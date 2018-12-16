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

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ccrockett/omniauth-keycloak. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Omniauth::Keycloak project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/ccrockett/omniauth-keycloak/blob/master/CODE_OF_CONDUCT.md).
