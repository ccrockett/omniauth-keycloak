require 'omniauth'
require 'omniauth-oauth2'
require 'json/jwt'

module OmniAuth
    module Strategies
        class KeycloakOpenId < OmniAuth::Strategies::OAuth2
            attr_reader :authorize_url
            attr_reader :token_url
            attr_reader :cert

            def setup_phase
                if @authorize_url.nil? || @token_url.nil?
                    realm = options.client_options[:realm].nil? ? options.client_id : options.client_options[:realm]
                    site = options.client_options[:site]
                    response = Faraday.get "#{options.client_options[:site]}/auth/realms/#{realm}/.well-known/openid-configuration"
                    if (response.status == 200)
                        json = MultiJson.load(response.body)
                        @certs_endpoint = json["jwks_uri"]
                        @userinfo_endpoint = json["userinfo_endpoint"]
                        @authorize_url = json["authorization_endpoint"].gsub(site, "")
                        @token_url = json["token_endpoint"].gsub(site, "")
                        options.client_options.merge!({
                            authorize_url: @authorize_url,
                            token_url: @token_url
                        })
                        certs = Faraday.get @certs_endpoint
                        if (certs.status == 200)
                            json = MultiJson.load(certs.body)
                            @cert = json["keys"][0]
                        else
                            #TODO: Throw Error
                            puts "Couldn't get Cert"
                        end 
                    else
                        #TODO: Throw Error
                        puts response.status
                    end
                end
            end

            def request_phase
                unless options.client_options['application_domain']
                    redirect client_auth_code_authorize_url
                    return
                end

                application_domain = URI.parse(options.client_options['application_domain']).host.downcase
                request_domain = URI.parse(request.url).host.downcase
                # if keycloak and the application live on the same domain we can just use the path and not the full domain
                if application_domain == request_domain
                    client_auth_code_authorize_url = client.auth_code.authorize_url({:redirect_uri => callback_url}.merge(authorize_params))
                    redirect"#{URI.parse(client_auth_code_authorize_url).path}?#{URI.parse(client_auth_code_authorize_url).query}"
                else
                    redirect client_auth_code_authorize_url
                end
            end

            def build_access_token
                verifier = request.params["code"]
                client.auth_code.get_token(verifier, 
                    {:redirect_uri => callback_url.gsub(/\?.+\Z/, "")}
                    .merge(token_params.to_hash(:symbolize_keys => true)), 
                    deep_symbolize(options.auth_token_params))
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
                'raw_info' => raw_info
            }
            end
        
            def raw_info
                id_token_string = access_token.token
                jwk = JSON::JWK.new(@cert)
                id_token = JSON::JWT.decode id_token_string, jwk
                id_token
            end

            OmniAuth.config.add_camelization('keycloak_openid', 'KeycloakOpenId')
        end
    end
end