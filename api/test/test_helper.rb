ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../../test/dummy/config/environment.rb',  __FILE__)
ActiveRecord::Migrator.migrations_paths = [File.expand_path('../../test/dummy/db/migrate', __FILE__)]
require 'rails/test_help'

# Require PushType testing setup
require 'push_type/testing/setup'
require 'push_type/testing/factories'

# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

class ActionController::TestCase
  before :all do
    @request.headers['Accept']        = 'application/json'
    @request.headers['Content-Type']  = 'application/json'
  end
end