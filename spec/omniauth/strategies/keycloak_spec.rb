require 'spec_helper'

RSpec.describe OmniAuth::Strategies::KeycloakOpenId do
  let(:body) {
    {
      "issuer": "http://localhost:8080/auth/realms/example-realm",
      "authorization_endpoint": "http://localhost:8080/auth/realms/example-realm/protocol/openid-connect/auth",
      "token_endpoint": "http://localhost:8080/auth/realms/example-realm/protocol/openid-connect/token",
      "token_introspection_endpoint": "http://localhost:8080/auth/realms/example-realm/protocol/openid-connect/token/introspect",
      "userinfo_endpoint": "http://localhost:8080/auth/realms/example-realm/protocol/openid-connect/userinfo",
      "end_session_endpoint": "http://localhost:8080/auth/realms/example-realm/protocol/openid-connect/logout",
      "jwks_uri": "http://localhost:8080/auth/realms/example-realm/protocol/openid-connect/certs",
      "check_session_iframe": "http://localhost:8080/auth/realms/example-realm/protocol/openid-connect/login-status-iframe.html",
      "grant_types_supported": ["authorization_code", "implicit", "refresh_token", "password", "client_credentials"],
      "response_types_supported": ["code", "none", "id_token", "token", "id_token token", "code id_token", "code token", "code id_token token"],
      "subject_types_supported": ["public", "pairwise"],
      "id_token_signing_alg_values_supported": ["RS256"],
      "userinfo_signing_alg_values_supported": ["RS256"],
      "request_object_signing_alg_values_supported": ["none", "RS256"],
      "response_modes_supported": ["query", "fragment", "form_post"],
      "registration_endpoint": "http://localhost:8080/auth/realms/example-realm/clients-registrations/openid-connect",
      "token_endpoint_auth_methods_supported": ["private_key_jwt", "client_secret_basic", "client_secret_post"],
      "token_endpoint_auth_signing_alg_values_supported": ["RS256"],
      "claims_supported": ["sub", "iss", "auth_time", "name", "given_name", "family_name", "preferred_username", "email"],
      "claim_types_supported": ["normal"],
      "claims_parameter_supported": false,
      "scopes_supported": ["openid", "offline_access"],
      "request_parameter_supported": true,
      "request_uri_parameter_supported": true
    }
  }

  context 'client options' do
    subject do
      stub_request(:get, "http://localhost:8080/auth/realms/example-realm/.well-known/openid-configuration")
        .to_return(status: 200, body: JSON.generate(body), headers: {})
      stub_request(:get, "http://localhost:8080/auth/realms/example-realm/protocol/openid-connect/certs")
        .to_return(status: 404, body: "", headers: {})
      OmniAuth::Strategies::KeycloakOpenId.new('keycloak-openid', 'Example-Client', 'b53c572b-9f3b-4e79-bf8b-f03c799ba6ec',
        client_options: {site: 'http://localhost:8080/', realm: 'example-realm'})
    end

    it 'should have the correct keycloak token url' do
      subject.setup_phase
      expect(subject.token_url).to eq('/auth/realms/example-realm/protocol/openid-connect/token')
    end

    it 'should have the correct keycloak authorization url' do
      subject.setup_phase
      expect(subject.authorize_url).to eq('/auth/realms/example-realm/protocol/openid-connect/auth')
    end
  end

  describe "test mode" do
    let(:config_url) { "http://localhost:8080/realms/example-realm/.well-known/openid-configuration" }

    subject do
      stub_request(:get, config_url)
      OmniAuth::Strategies::KeycloakOpenId.new('keycloak-openid', 'Example-Client', 'b53c572b-9f3b-4e79-bf8b-f03c799ba6ec',
                                               client_options: {site: 'http://localhost:8080/', realm: 'example-realm', base_url: ''})
    end

    before do
      OmniAuth.config.test_mode = true
    end

    after do
      OmniAuth.config.test_mode = false
    end

    it 'should not fetch configuration when in test mode' do
      subject.setup_phase
      expect(a_request(:get, config_url)).not_to have_been_made
      OmniAuth.config.test_mode = false
    end
  end

  describe 'client base_url option set' do
    context 'to blank string' do
      let(:new_body_endpoints) {
        {
          "authorization_endpoint": "http://localhost:8080/realms/example-realm/protocol/openid-connect/auth",
          "token_endpoint": "http://localhost:8080/realms/example-realm/protocol/openid-connect/token",
          "jwks_uri": "http://localhost:8080/realms/example-realm/protocol/openid-connect/certs"
        }
      }

      subject do
        stub_request(:get, "http://localhost:8080/realms/example-realm/.well-known/openid-configuration")
          .to_return(status: 200, body: JSON.generate(body.merge(new_body_endpoints)), headers: {})
        stub_request(:get, "http://localhost:8080/realms/example-realm/protocol/openid-connect/certs")
          .to_return(status: 404, body: "", headers: {})
        OmniAuth::Strategies::KeycloakOpenId.new('keycloak-openid', 'Example-Client', 'b53c572b-9f3b-4e79-bf8b-f03c799ba6ec',
          client_options: {site: 'http://localhost:8080/', realm: 'example-realm', base_url: ''})
      end

      it 'should have the correct keycloak token url' do
        subject.setup_phase
        expect(subject.token_url).to eq('/realms/example-realm/protocol/openid-connect/token')
      end

      it 'should have the correct keycloak authorization url' do
        subject.setup_phase
        expect(subject.authorize_url).to eq('/realms/example-realm/protocol/openid-connect/auth')
      end
    end

    context 'to invalid string' do
      subject do
        stub_request(:get, "http://localhost:8080/realms/example-realm/.well-known/openid-configuration")
          .to_return(status: 200, body: JSON.generate(body), headers: {})
        stub_request(:get, "http://localhost:8080/auth/realms/example-realm/protocol/openid-connect/certs")
          .to_return(status: 404, body: "", headers: {})
        OmniAuth::Strategies::KeycloakOpenId.new('keycloak-openid', 'Example-Client', 'b53c572b-9f3b-4e79-bf8b-f03c799ba6ec',
          client_options: {site: 'http://localhost:8080/', realm: 'example-realm', base_url: 'test'})
      end

      it 'raises Configuration Error' do
        expect{ subject.setup_phase }
          .to raise_error(OmniAuth::Strategies::KeycloakOpenId::ConfigurationError)
      end
    end

    context 'to /authorize' do

      let(:new_body_endpoints) {
        {
          "authorization_endpoint": "http://localhost:8080/authorize/realms/example-realm/protocol/openid-connect/auth",
          "token_endpoint": "http://localhost:8080/authorize/realms/example-realm/protocol/openid-connect/token",
          "jwks_uri": "http://localhost:8080/authorize/realms/example-realm/protocol/openid-connect/certs"
        }
      }

      subject do
        stub_request(:get, "http://localhost:8080/authorize/realms/example-realm/.well-known/openid-configuration")
          .to_return(status: 200, body: JSON.generate(body.merge(new_body_endpoints)), headers: {})
        stub_request(:get, "http://localhost:8080/authorize/realms/example-realm/protocol/openid-connect/certs")
          .to_return(status: 404, body: "", headers: {})
        OmniAuth::Strategies::KeycloakOpenId.new('keycloak-openid', 'Example-Client', 'b53c572b-9f3b-4e79-bf8b-f03c799ba6ec',
          client_options: {site: 'http://localhost:8080/', realm: 'example-realm', base_url: '/authorize'})
      end

      it 'should have the correct keycloak token url' do
        subject.setup_phase
        expect(subject.token_url).to eq('/authorize/realms/example-realm/protocol/openid-connect/token')
      end

      it 'should have the correct keycloak authorization url' do
        subject.setup_phase
        expect(subject.authorize_url).to eq('/authorize/realms/example-realm/protocol/openid-connect/auth')
      end
    end
  end

  context 'client setup with a proc' do
    subject do
      OmniAuth::Strategies::KeycloakOpenId.new('keycloak-openid', setup: proc { throw :setup_proc_was_called })
    end

    it 'should call the proc' do
      expect { subject.setup_phase }.to throw_symbol :setup_proc_was_called
    end
  end

  describe 'errors processing' do
    context 'when site contains /auth part' do
      subject do
        OmniAuth::Strategies::KeycloakOpenId.new('keycloak-openid', 'Example-Client', 'b53c572b-9f3b-4e79-bf8b-f03c799ba6ec',
                                                 client_options: {site: 'http://localhost:8080/auth', realm: 'example-realm', raise_on_failure: true})
      end

      it 'raises Configuration Error' do
        expect{ subject.setup_phase }
          .to raise_error(OmniAuth::Strategies::KeycloakOpenId::ConfigurationError)
      end
    end

    context 'when raise_on_failure option is true' do
      context 'when openid configuration endpoint returns error response' do
        subject do
          stub_request(:get, "http://localhost:8080/auth/realms/example-realm/.well-known/openid-configuration")
            .to_return(status: 404, body: "", headers: {})
          OmniAuth::Strategies::KeycloakOpenId.new('keycloak-openid', 'Example-Client', 'b53c572b-9f3b-4e79-bf8b-f03c799ba6ec',
                                                   client_options: {site: 'http://localhost:8080', realm: 'example-realm', raise_on_failure: true})
        end

        it 'raises Integration Error' do
          expect{ subject.setup_phase }
            .to raise_error(OmniAuth::Strategies::KeycloakOpenId::IntegrationError)
        end
      end

      context 'when certificates endpoint returns error response' do
        subject do
          stub_request(:get, "http://localhost:8080/auth/realms/example-realm/.well-known/openid-configuration")
            .to_return(status: 200, body: JSON.generate(body), headers: {})
          stub_request(:get, "http://localhost:8080/auth/realms/example-realm/protocol/openid-connect/certs")
            .to_return(status: 404, body: "", headers: {})
          OmniAuth::Strategies::KeycloakOpenId.new('keycloak-openid', 'Example-Client', 'b53c572b-9f3b-4e79-bf8b-f03c799ba6ec',
                                                   client_options: {site: 'http://localhost:8080', realm: 'example-realm', raise_on_failure: true})
        end

        it 'raises Integration Error' do
          expect{ subject.setup_phase }
            .to raise_error(OmniAuth::Strategies::KeycloakOpenId::IntegrationError)
        end
      end
    end
  end

  describe '#raw_info' do
    let(:client_id) { 'Example-Client' }
    let(:site) { 'http://localhost:8080/' }
    let(:realm) { 'example-realm' }
    let(:issuer) { 'http://localhost:8080/auth/realms/example-realm' }
    let(:rsa_key) { OpenSSL::PKey::RSA.generate(2048) }
    let(:jwk) { JSON::JWK.new(rsa_key) }

    subject do
      strategy = OmniAuth::Strategies::KeycloakOpenId.new('keycloak-openid', client_id, 'client-secret',
        client_options: {site: site, realm: realm})
      strategy.instance_variable_set(:@certs, [jwk])
      strategy
    end

    def id_token_string(claims: {}, alg: :RS256, key: rsa_key, set_kid: true)
      jwt = JSON::JWT.new({
        'iss' => issuer,
        'aud' => client_id,
        'sub' => 'user-123',
        'exp' => (Time.now + 3600).to_i,
        'iat' => Time.now.to_i
      }.merge(claims))

      return jwt.to_s if alg == :none

      jwt.kid = jwk[:kid] if set_kid
      jwt.sign(key, alg).to_s
    end

    def stub_access_token(strategy, id_token)
      access_token = double('AccessToken')
      allow(access_token).to receive(:[]).with('id_token').and_return(id_token)
      allow(access_token).to receive(:token).and_return('opaque-oauth-access-token-should-not-be-decoded')
      strategy.access_token = access_token
    end

    it 'decodes the OIDC id_token from the token response, not the OAuth access token' do
      stub_access_token(subject, id_token_string)

      expect(subject.raw_info['sub']).to eq('user-123')
    end

    it 'rejects tokens with alg: none' do
      stub_access_token(subject, id_token_string(alg: :none))

      expect { subject.raw_info }.to raise_error(JSON::JWT::UnexpectedAlgorithm)
    end

    it 'rejects HS256-signed tokens (algorithm confusion)' do
      stub_access_token(subject, id_token_string(alg: :HS256, key: 'attacker-controlled-secret', set_kid: false))

      expect { subject.raw_info }.to raise_error(JSON::JWT::UnexpectedAlgorithm)
    end

    it 'rejects tokens with an unexpected issuer' do
      stub_access_token(subject, id_token_string(claims: {'iss' => 'http://evil.example.com/auth/realms/example-realm'}))

      expect { subject.raw_info }.to raise_error(OmniAuth::Strategies::KeycloakOpenId::InvalidIdToken, /issuer/)
    end

    it 'rejects tokens with an unexpected audience' do
      stub_access_token(subject, id_token_string(claims: {'aud' => 'some-other-client'}))

      expect { subject.raw_info }.to raise_error(OmniAuth::Strategies::KeycloakOpenId::InvalidIdToken, /audience/)
    end

    it 'accepts an audience array that includes the client id' do
      stub_access_token(subject, id_token_string(claims: {'aud' => [client_id, 'some-other-client'], 'azp' => client_id}))

      expect(subject.raw_info['sub']).to eq('user-123')
    end

    it 'rejects an audience array with no azp claim' do
      stub_access_token(subject, id_token_string(claims: {'aud' => [client_id, 'some-other-client']}))

      expect { subject.raw_info }.to raise_error(OmniAuth::Strategies::KeycloakOpenId::InvalidIdToken, /azp/)
    end

    it 'accepts an audience array when the client id is not the first element' do
      stub_access_token(subject, id_token_string(claims: {'aud' => ['account', client_id], 'azp' => client_id}))

      expect(subject.raw_info['sub']).to eq('user-123')
    end

    it 'rejects an audience array that does not include the client id' do
      stub_access_token(subject, id_token_string(claims: {'aud' => ['account', 'some-other-client']}))

      expect { subject.raw_info }.to raise_error(OmniAuth::Strategies::KeycloakOpenId::InvalidIdToken, /audience/)
    end

    it 'rejects tokens with no aud claim' do
      stub_access_token(subject, id_token_string(claims: {'aud' => nil}))

      expect { subject.raw_info }.to raise_error(OmniAuth::Strategies::KeycloakOpenId::InvalidIdToken, /audience/)
    end

    it 'rejects tokens authorized for a different party (azp)' do
      stub_access_token(subject, id_token_string(claims: {'aud' => [client_id, 'some-other-client'], 'azp' => 'some-other-client'}))

      expect { subject.raw_info }.to raise_error(OmniAuth::Strategies::KeycloakOpenId::InvalidIdToken, /azp/)
    end

    it 'accepts tokens whose azp is the client id' do
      stub_access_token(subject, id_token_string(claims: {'azp' => client_id}))

      expect(subject.raw_info['sub']).to eq('user-123')
    end

    it 'rejects tokens from a different realm on the same host' do
      stub_access_token(subject, id_token_string(claims: {'iss' => 'http://localhost:8080/auth/realms/other-realm'}))

      expect { subject.raw_info }.to raise_error(OmniAuth::Strategies::KeycloakOpenId::InvalidIdToken, /issuer/)
    end

    it 'rejects tokens with no iss claim' do
      stub_access_token(subject, id_token_string(claims: {'iss' => nil}))

      expect { subject.raw_info }.to raise_error(OmniAuth::Strategies::KeycloakOpenId::InvalidIdToken, /issuer/)
    end

    it 'rejects RS256 tokens signed by an untrusted key' do
      stub_access_token(subject, id_token_string(key: OpenSSL::PKey::RSA.generate(2048)))

      expect { subject.raw_info }.to raise_error(JSON::JWS::VerificationFailed)
    end

    it 'rejects HS256 tokens that carry a valid kid' do
      stub_access_token(subject, id_token_string(alg: :HS256, key: rsa_key.public_key.to_pem))

      expect { subject.raw_info }.to raise_error(JSON::JWT::UnexpectedAlgorithm)
    end

    it 'rejects tokens signed with another RSA algorithm (the pin is RS256 only)' do
      stub_access_token(subject, id_token_string(alg: :PS256))

      expect { subject.raw_info }.to raise_error(JSON::JWT::UnexpectedAlgorithm)
    end

    it 'rejects tokens with no kid header' do
      stub_access_token(subject, id_token_string(set_kid: false))

      expect { subject.raw_info }.to raise_error(JSON::JWK::Set::KidNotFound)
    end

    it 'rejects expired tokens' do
      stub_access_token(subject, id_token_string(claims: {'exp' => (Time.now - 120).to_i}))

      expect { subject.raw_info }.to raise_error(OmniAuth::Strategies::KeycloakOpenId::InvalidIdToken, /expired/)
    end

    it 'accepts tokens that expired within the clock-skew leeway' do
      stub_access_token(subject, id_token_string(claims: {'exp' => (Time.now - 30).to_i}))

      expect(subject.raw_info['sub']).to eq('user-123')
    end

    it 'rejects tokens with no exp claim' do
      stub_access_token(subject, id_token_string(claims: {'exp' => nil}))

      expect { subject.raw_info }.to raise_error(OmniAuth::Strategies::KeycloakOpenId::InvalidIdToken, /exp/)
    end

    it 'rejects tokens that are not yet valid (nbf)' do
      stub_access_token(subject, id_token_string(claims: {'nbf' => (Time.now + 300).to_i}))

      expect { subject.raw_info }.to raise_error(OmniAuth::Strategies::KeycloakOpenId::InvalidIdToken, /not valid before/)
    end

    it 'fails with InvalidIdToken when the token response has no id_token' do
      stub_access_token(subject, nil)

      expect { subject.raw_info }.to raise_error(OmniAuth::Strategies::KeycloakOpenId::InvalidIdToken, /openid/)
    end

    it 'fails with IntegrationError when signing keys were never loaded' do
      subject.instance_variable_set(:@certs, nil)
      stub_access_token(subject, id_token_string)

      expect { subject.raw_info }.to raise_error(OmniAuth::Strategies::KeycloakOpenId::IntegrationError, /signing keys/)
    end

    it 'verifies a real OAuth2::AccessToken against keys in the shape setup_phase stores (parsed JSON hashes)' do
      subject.instance_variable_set(:@certs, JSON.parse(JSON.generate('keys' => [jwk.as_json]))['keys'])
      subject.access_token = OAuth2::AccessToken.from_hash(
        OAuth2::Client.new(client_id, 'client-secret', site: site),
        'access_token' => 'opaque-oauth-access-token', 'id_token' => id_token_string
      )

      expect(subject.raw_info['sub']).to eq('user-123')
    end

    context 'with base_url "" (Keycloak without the /auth prefix)' do
      subject do
        strategy = OmniAuth::Strategies::KeycloakOpenId.new('keycloak-openid', client_id, 'client-secret',
          client_options: {site: site, realm: realm, base_url: ''})
        strategy.instance_variable_set(:@certs, [jwk])
        strategy
      end

      it 'accepts the issuer without /auth' do
        stub_access_token(subject, id_token_string(claims: {'iss' => 'http://localhost:8080/realms/example-realm'}))

        expect(subject.raw_info['sub']).to eq('user-123')
      end

      it 'rejects the /auth issuer' do
        stub_access_token(subject, id_token_string)

        expect { subject.raw_info }.to raise_error(OmniAuth::Strategies::KeycloakOpenId::InvalidIdToken, /issuer/)
      end
    end

    context 'when setup_phase has fetched the discovery document' do
      let(:discovery_issuer) { 'https://sso.example.com/realms/example-realm' }

      subject do
        stub_request(:get, 'http://localhost:8080/auth/realms/example-realm/.well-known/openid-configuration')
          .to_return(status: 200, body: JSON.generate(body.merge(issuer: discovery_issuer)), headers: {})
        stub_request(:get, 'http://localhost:8080/auth/realms/example-realm/protocol/openid-connect/certs')
          .to_return(status: 200, body: JSON.generate('keys' => [jwk.as_json]), headers: {})
        strategy = OmniAuth::Strategies::KeycloakOpenId.new('keycloak-openid', client_id, 'client-secret',
          client_options: {site: site, realm: realm})
        strategy.setup_phase
        strategy
      end

      it 'checks iss against the discovery issuer' do
        stub_access_token(subject, id_token_string(claims: {'iss' => discovery_issuer}))

        expect(subject.raw_info['sub']).to eq('user-123')
      end

      it 'rejects the site/realm-derived issuer when discovery names a different one' do
        stub_access_token(subject, id_token_string)

        expect { subject.raw_info }.to raise_error(OmniAuth::Strategies::KeycloakOpenId::InvalidIdToken, /issuer/)
      end

      context 'and the discovery issuer is empty' do
        let(:discovery_issuer) { '' }

        it 'falls back to the site/realm-derived issuer' do
          stub_access_token(subject, id_token_string)

          expect(subject.raw_info['sub']).to eq('user-123')
        end
      end
    end

    it 'requests the openid scope by default, alongside custom authorize_options' do
      strategy = OmniAuth::Strategies::KeycloakOpenId.new('keycloak-openid', client_id, 'client-secret',
        client_options: {site: site, realm: realm}, authorize_options: [:kc_idp_hint])
      allow(strategy).to receive(:session).and_return({})

      expect(strategy.authorize_params[:scope]).to eq('openid')
    end

    it 'derives the expected issuer from the client id when no realm is configured' do
      strategy = OmniAuth::Strategies::KeycloakOpenId.new('keycloak-openid', client_id, 'client-secret',
        client_options: {site: site})

      expect(strategy.expected_issuer).to eq('http://localhost:8080/auth/realms/Example-Client')
    end
  end
end
