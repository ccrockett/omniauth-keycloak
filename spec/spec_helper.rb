require "bundler/setup"
require "omniauth/strategies/keycloak-openid"
require "webmock/rspec"

if RUBY_VERSION >= "1.9"
  require "simplecov"

  SimpleCov.start do
    minimum_coverage(93.00)
  end
end

require "rspec"
require "omniauth"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
  config.extend OmniAuth::Test::StrategyMacros, :type => :strategy
end
