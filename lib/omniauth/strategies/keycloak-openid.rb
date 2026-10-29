require 'omniauth'
require 'omniauth-oauth2'
require 'json/jwt'
require 'uri'

module OmniAuth
    module Strategies
        class KeycloakOpenId < OmniAuth::Strategies::OAuth2

            class Error < RuntimeError; end
            class ConfigurationError < Error; end
            class IntegrationError < Error; end
            class InvalidIdToken < Error; end

            ID_TOKEN_ALGORITHM = :RS256
            # Leeway in seconds for clock drift between this host and Keycloak when checking exp/nbf.
            ID_TOKEN_CLOCK_SKEW = 60

            # raw_info verifies the OIDC id_token, so ask for the scope that makes it an OIDC request.
            option :authorize_params, { scope: 'openid' }

            attr_reader :authorize_url
            attr_reader :token_url
            attr_reader :certs

            def setup_phase
                super

                if (@authorize_url.nil? || @token_url.nil?) && !OmniAuth.config.test_mode

                    prevent_site_option_mistake

                    realm = realm_name
                    site = options.client_options[:site]

                    raise_on_failure = options.client_options.fetch(:raise_on_failure, false)

                    config_url = URI.join(site, "#{auth_url_base}/realms/#{realm}/.well-known/openid-configuration")

                    log :debug, "Going to get Keycloak configuration. URL: #{config_url}"
                    response = Faraday.get config_url
                    if (response.status == 200)
                        json = JSON.parse(response.body)

                        issuer = json["issuer"]
                        if issuer.is_a?(String) && !issuer.empty?
                            @issuer = issuer
                            if @issuer != configured_issuer
                                log :warn, "Keycloak discovery issuer #{@issuer.inspect} differs from the configured " \
                                           "site/realm #{configured_issuer.inspect}; id_tokens are checked against the discovery issuer"
                            end
                        else
                            log :warn, "Keycloak discovery document has no issuer; id_tokens are checked against " \
                                       "the configured site/realm #{configured_issuer.inspect}"
                        end
                        @certs_endpoint = json["jwks_uri"]
                        @userinfo_endpoint = json["userinfo_endpoint"]
                        @authorize_url = URI(json["authorization_endpoint"]).path
                        @token_url = URI(json["token_endpoint"]).path

                        log_config(json)

                        options.client_options.merge!({
                            authorize_url: @authorize_url,
                            token_url: @token_url
                                                      })
                        log :debug, "Going to get certificates. URL: #{@certs_endpoint}"
                        certs = Faraday.get @certs_endpoint
                        if (certs.status == 200)
                            json = JSON.parse(certs.body)
                            @certs = json["keys"]
                            log :debug, "Successfully got certificate. Certificate length: #{@certs.length}"
                        else
                            message = "Couldn't get certificate. URL: #{@certs_endpoint}"
                            log :error, message
                            raise IntegrationError, message if raise_on_failure
                        end
                    else
                        message = "Keycloak configuration request failed with status: #{response.status}. " \
                                  "URL: #{config_url}"
                        log :error, message
                        raise IntegrationError, message if raise_on_failure
                    end
                end
            end

            def auth_url_base
              return '/auth' unless options.client_options[:base_url]
              base_url = options.client_options[:base_url]
              return base_url if (base_url == '' || base_url[0] == '/')

              raise ConfigurationError, "Keycloak base_url option should start with '/'. Current value: #{base_url}"
            end

            def prevent_site_option_mistake
              site = options.client_options[:site]
              return unless site =~ /\/auth$/

              raise ConfigurationError, "Keycloak site parameter should not include /auth part, only domain. Current value: #{site}"
            end

            def log_config(config_json)
              log_keycloak_config = options.client_options.fetch(:log_keycloak_config, false)
              log :debug, "Successfully got Keycloak config"
              log :debug, "Keycloak config: #{config_json}" if log_keycloak_config
              log :debug, "Certs endpoint: #{@certs_endpoint}"
              log :debug, "Userinfo endpoint: #{@userinfo_endpoint}"
              log :debug, "Authorize url: #{@authorize_url}"
              log :debug, "Token url: #{@token_url}"
            end

            def build_access_token
                verifier = request.params["code"]
                client.auth_code.get_token(verifier,
                    {:redirect_uri => callback_url.gsub(/\?.+\Z/, "")}
                    .merge(token_params.to_hash(:symbolize_keys => true)),
                    deep_symbolize(options.auth_token_params))
            end

            def request_phase
                options.authorize_options.each do |key|
                  options[key] = request.params[key.to_s] if options[key].nil?
                end
                super
            end

            uid{ raw_info['sub'] }

            info do
            {
                :name => raw_info['name'],
                :email => raw_info['email'],
                :first_name => raw_info['given_name'],
                :last_name => raw_info['family_name']
            }
            end

            extra do
            {
                'raw_info' => raw_info,
                'id_token' => access_token['id_token']
            }
            end

            def raw_info
                id_token_string = access_token['id_token']
                if id_token_string.nil? || id_token_string.empty?
                    raise InvalidIdToken, "Token response has no id_token. Is the 'openid' scope requested?"
                end
                if @certs.nil? || @certs.empty?
                    raise IntegrationError, "No Keycloak signing keys loaded (certs endpoint: #{@certs_endpoint.inspect}); cannot verify id_token"
                end

                jwks = JSON::JWK::Set.new(@certs)
                id_token = JSON::JWT.decode id_token_string, jwks, ID_TOKEN_ALGORITHM
                verify_issuer! id_token
                verify_audience! id_token
                verify_lifetime! id_token
                id_token
            end

            # The issuer from the discovery document, which is also where the signing keys came from;
            # falls back to the URL derived from site/realm when setup_phase has not fetched it.
            def expected_issuer
                @issuer || configured_issuer
            end

            def configured_issuer
                realm = realm_name
                site = options.client_options[:site]

                URI.join(site, "#{auth_url_base}/realms/#{realm}").to_s
            end

            def realm_name
                options.client_options[:realm].nil? ? options.client_id : options.client_options[:realm]
            end

            def verify_issuer!(id_token)
                return if id_token['iss'] == expected_issuer

                raise InvalidIdToken, "Unexpected id_token issuer: #{id_token['iss'].inspect} (expected #{expected_issuer.inspect})"
            end

            def verify_audience!(id_token)
                audience = Array(id_token['aud'])
                unless audience.include?(options.client_id)
                    raise InvalidIdToken, "Unexpected id_token audience: #{id_token['aud'].inspect} (expected to include #{options.client_id.inspect})"
                end

                azp = id_token['azp']
                return if azp == options.client_id
                return if azp.nil? && audience.length == 1

                raise InvalidIdToken, "Unexpected id_token azp: #{azp.inspect} (expected #{options.client_id.inspect})"
            end

            def verify_lifetime!(id_token)
                now = Time.now.to_i
                exp = id_token['exp']
                raise InvalidIdToken, "id_token has no numeric exp claim: #{exp.inspect}" unless exp.is_a?(Numeric)
                raise InvalidIdToken, "id_token expired at #{exp} (now #{now})" if now > exp + ID_TOKEN_CLOCK_SKEW

                nbf = id_token['nbf']
                return unless nbf.is_a?(Numeric) && now + ID_TOKEN_CLOCK_SKEW < nbf

                raise InvalidIdToken, "id_token not valid before #{nbf} (now #{now})"
            end

            OmniAuth.config.add_camelization('keycloak_openid', 'KeycloakOpenId')
        end
    end
end
