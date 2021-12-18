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
end
