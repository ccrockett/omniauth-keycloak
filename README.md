# Omniauth::Keycloak

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'omniauth-keycloak'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install omniauth-keycloak

## Usage

`OmniAuth::Strategies::Keycloak` is simply a Rack middleware. Read the OmniAuth docs for detailed instructions: https://github.com/intridea/omniauth.

Here's a quick example, adding the middleware to a Rails app in `config/initializers/omniauth.rb`:

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :keycloak_openid, 'Example-Client', '19cca35f-dddd-473a-bdd5-03f00d61d884',
    client_options: {site: 'https://example.keycloak-url.com', realm: 'example-realm'}
end
```

## Devise Usage
Adapted from [Devise OmniAuth Instructions](https://github.com/plataformatec/devise/wiki/OmniAuth:-Overview)

```ruby
# app/models/user.rb
class User < ApplicationRecord
  #...
  devise :omniauthable, omniauth_providers: %i[keycloakopenid]
  #...
end

# config/initializers/devise.rb
config.omniauth :keycloak_openid, "Example-Client-Name", "example-secret-if-configured", client_options: { site: "https://example.keycloak-url.com", realm: "example-realm" }, :strategy_class => OmniAuth::Strategies::KeycloakOpenId

# Below controller assumes callback route configuration following 
# in config/routes.rb
Devise.setup do |config|
  # ...
  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }
end

# app/controllers/users/omniauth_callbacks_controller.rb
class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def keycloakopenid
    Rails.logger.debug(request.env["omniauth.auth"])
    @user = User.from_omniauth(request.env["omniauth.auth"])
    if @user.persisted?
      sign_in_and_redirect @user, event: :authentication
    else
      session["devise.keycloakopenid_data"] = request.env["omniauth.auth"]
      redirect_to new_user_registration_url
    end
  end

  def failure
    redirect_to root_path
  end
end

```

## API Gateway Support

Sometimes your Keycloak server and your application have the same domain name on the same path. This is 
very common when using an api gateway service such as Mulesoft or Mashable where the requests are sent to different applications based on the path of the URI. 

To configure simply add the `application_domain` to the client_options. If the `application_domain` matches the `site`
then the redirect will only use the path. Otherwise it will use the full URI. Useful where staging has a seperate domain for your Keycloak server but
production uses an API gateway.

```ruby
Rails.application.config.middleware.use OmniAuth::Builder do
  provider :keycloak_openid, 'Example-Client', '19cca35f-dddd-473a-bdd5-03f00d61d884',
    client_options: {site: 'https://example.mydomain.com', application_domain: 'https://example.mydomain.com', realm: 'example-realm'}
end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ccrockett/omniauth-keycloak. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Omniauth::Keycloak project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/ccrockett/omniauth-keycloak/blob/master/CODE_OF_CONDUCT.md).
