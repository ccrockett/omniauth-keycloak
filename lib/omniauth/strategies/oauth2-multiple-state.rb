require "oauth2"
require "omniauth"
require "securerandom"
require "socket"       # for SocketError
require "timeout"      # for Timeout::Error
require "base64"
require "digest"
require "openssl"
require "json"

module OmniAuth
  module Strategies
    # Authentication strategy for connecting with APIs constructed using
    # the [OAuth 2.0 Specification](http://tools.ietf.org/html/draft-ietf-oauth-v2-10).
    # You must generally register your application with the provider and
    # utilize an application id and secret in order to authenticate using
    # OAuth 2.0.
    class OAuth2MultipleState
      include OmniAuth::Strategy

      STATE_TTL = 15 * 60

      def state_secret
        ENV.fetch("OAUTH_STATE_SECRET")
      end

      def b64url_encode(bytes)
        Base64.urlsafe_encode64(bytes, padding: false)
      end

      def b64url_decode(str)
        padding = "=" * ((4 - str.length % 4) % 4)
        Base64.urlsafe_decode64(str + padding)
      end

      def issue_signed_state
        # payload icerisinde zaman damgasi (iat), benzersiz id (jti) ve versiyon (v) var
        payload = {
          "iat" => Time.now.to_i,
          "jti" => SecureRandom.hex(8),
          "v"   => 1
        }

        # payload'i json'a cevir, base64'le, imzala, imzayi da base64'le
        raw = b64url_encode(payload.to_json)
        sig = OpenSSL::HMAC.digest("SHA256", state_secret, raw)
        state = "#{raw}.#{b64url_encode(sig)}"
        [state, payload]
      end

      # state degerini dogrula
      def verify_signed_state(state_param)
        # state'i yaratirken "<raw>.<sig_b64>" seklinde olusturduk
        # burada bu sekilde ayirip imzayi kontrol ediyoruz
        raw, sig_b64 = state_param.to_s.split(".", 2)

        # eksik parca varsa imza hatali
        return [:bad_signature, nil] if raw.nil? || sig_b64.nil?

        # imzayi base64'ten decode et
        given_sig = b64url_decode(sig_b64) rescue nil

        # imza yoksa imza hatali
        return [:bad_signature, nil] if given_sig.nil?

        # imzayi hesapla ve karsilastir
        calc_sig = OpenSSL::HMAC.digest("SHA256", state_secret, raw)
        unless ActiveSupport::SecurityUtils.secure_compare(calc_sig, given_sig)
          return [:bad_signature, nil]
        end

        # imza dogru, payload'i al
        payload_json = b64url_decode(raw) rescue nil
        payload = JSON.parse(payload_json) rescue nil

        # payload uygun degilse imza hatali
        return [:bad_signature, nil] unless payload.is_a?(Hash) && payload["jti"] && payload["iat"] && payload["v"] == 1

        # payload icerisindeki zaman damgasina bak
        iat = Integer(payload["iat"]) rescue nil

        # zaman damgasi uygun degilse imza hatali
        return [:bad_signature, nil] if iat.nil?

        # zaman damgasi cok eskiyse oturum suresi dolmus
        if Time.now.to_i - iat > STATE_TTL
          return [:expired, payload]
        end

        # her sey yolunda, imza ve zaman damgasi dogru
        [:ok, payload]
      end

      def self.inherited(subclass)
        OmniAuth::Strategy.included(subclass)
      end

      args [:client_id, :client_secret]

      option :client_id, nil
      option :client_secret, nil
      option :client_options, {}
      option :authorize_params, {}
      option :authorize_options, [:scope]
      option :token_params, {}
      option :token_options, []
      option :auth_token_params, {}
      option :provider_ignores_state, false

      attr_accessor :access_token

      def client
        ::OAuth2::Client.new(options.client_id, options.client_secret, deep_symbolize(options.client_options))
      end

      credentials do
        hash = {"token" => access_token.token}
        hash.merge!("refresh_token" => access_token.refresh_token) if access_token.expires? && access_token.refresh_token
        hash.merge!("expires_at" => access_token.expires_at) if access_token.expires?
        hash.merge!("expires" => access_token.expires?)
        hash
      end

      def request_phase
        redirect client.auth_code.authorize_url({:redirect_uri => callback_url}.merge(authorize_params))
      end

      def authorize_params
        # state degerini imzali olarak olustur
        signed_state, payload = issue_signed_state

        # imzali state degerini authorize paramlarina ekle
        options.authorize_params[:state] = signed_state
        params = options.authorize_params.merge(options_for("authorize"))

        code_verifier, code_challenge = generate_pkce_pair
        session["pkce.code_verifier"] = code_verifier
        params[:code_challenge] = code_challenge
        params[:code_challenge_method] = "S256"

        if OmniAuth.config.test_mode
          @env ||= {}
          @env["rack.session"] ||= {}
        end
        session["omniauth.states"] ||= []
        session["omniauth.states"] << params[:state]

        session["omniauth.state_origins"] ||= {}
        session["omniauth.state_origins"][params[:state]] = session['omniauth.origin']

        session['omniauth.states'] = session['omniauth.states'].last(5) if session["omniauth.states"].length > 5
        session['omniauth.state_origins'] = session['omniauth.state_origins'].to_a.last(5).to_h if session["omniauth.state_origins"].length > 5

        params
      end

      def token_params
        options.token_params.merge(options_for("token"))
      end

      def callback_phase
        error = request.params["error_reason"] || request.params["error"]
        error_description = request.params["error_description"]

        return fail_with_error(:session_expired_on_tab, request.params) if session_expired_on_tab?(error, error_description)
        return fail_with_error(:oauth_error, request.params) if error

        verdict, meta = classify_state(request.params)
        case verdict
        when :ok
        when :csrf_bad_signature
          return fail_with_error(:csrf_bad_signature, request.params) # real CSRF/probe
        when :csrf_expired
          return fail_with_error(:csrf_expired, request.params)       # likely bookmark
        when :csrf_mismatch
          return fail_with_error(:csrf_detected, request.params)      # mismatch (bookmark/probe)
        else
          return fail_with_error(:csrf_detected, request.params)
        end

        self.access_token = build_access_token
        self.access_token = access_token.refresh! if access_token.expired?

        if session["omniauth.state_origins"] && request.params["state"]
          env["omniauth.origin"] = session["omniauth.state_origins"].delete(request.params["state"])
        end

        super
      rescue ::OAuth2::Error => e
        fail!(:invalid_credentials, e)
      rescue ::Timeout::Error, ::Errno::ETIMEDOUT => e
        fail!(:timeout, e)
      rescue ::SocketError => e
        fail!(:failed_to_connect, e)
      end
      

    protected

      def classify_state(params)
        # state parametresini al
        state = params["state"].to_s

        # state yoksa bad signature
        return [:csrf_bad_signature, :missing] if state.empty?

        # state degerini dogrula
        sig_res, payload = verify_signed_state(state)

        case sig_res
        when :bad_signature
          return [:csrf_bad_signature, nil]  # forged/tempered → real CSRF
        when :expired
          return [:csrf_expired, payload]
        when :ok
          if session["omniauth.states"].to_s.empty?
            return [:csrf_mismatch, :no_session_window]
          end
          if session["omniauth.states"].delete(state)
            return [:ok, payload]
          else
            return [:csrf_mismatch, :not_in_window]
          end
        else
          return [:csrf_bad_signature, nil]
        end
      end

      def generate_pkce_pair
        code_verifier = SecureRandom.urlsafe_base64(32)
        code_challenge = Base64.urlsafe_encode64(Digest::SHA256.digest(code_verifier)).tr("=", "")
        [code_verifier, code_challenge]
      end

      def build_access_token
        verifier = request.params["code"]
        client.auth_code.get_token(verifier, {:redirect_uri => callback_url}.merge(token_params.to_hash(:symbolize_keys => true)), deep_symbolize(options.auth_token_params))
      end

      def deep_symbolize(options)
        hash = {}
        options.each do |key, value|
          hash[key.to_sym] = value.is_a?(Hash) ? deep_symbolize(value) : value
        end
        hash
      end

      def options_for(option)
        hash = {}
        options.send(:"#{option}_options").select { |key| options[key] }.each do |key|
          hash[key.to_sym] = options[key]
        end
        hash
      end

      def session_expired_on_tab?(error, error_description)
        return false unless error
        return false unless error == 'temporarily_unavailable' && error_description == 'authentication_expired'

        true
      end

      def fail_with_error(error, params)
        exception = CallbackError.new(error, params["error_description"] || params["error_reason"], params["error_uri"])
        fail!(error, exception)
      end
      
      # An error that is indicated in the OAuth 2.0 callback.
      # This could be a `redirect_uri_mismatch` or other
      class CallbackError < StandardError
        attr_accessor :error, :error_reason, :error_uri

        def initialize(error, error_reason = nil, error_uri = nil)
          self.error = error
          self.error_reason = error_reason
          self.error_uri = error_uri
        end

        def message
          [error, error_reason, error_uri].compact.join(" | ")
        end
      end
    end
  end
end

OmniAuth.config.add_camelization "oauth2", "OAuth2"