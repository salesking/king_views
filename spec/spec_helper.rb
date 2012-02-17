#$LOAD_PATH.unshift(File.dirname(__FILE__))
#$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

# Configure Rails Envinronment
ENV["RAILS_ENV"] = "test"

# only start SimpleCov on ruby 1.9.x
if RUBY_VERSION[0..2].to_f >= 1.9
  require 'simplecov'
  SimpleCov.start
end


require File.expand_path("../rails_app/config/environment.rb",  __FILE__)
require "rspec/rails"


ActionMailer::Base.delivery_method = :test
ActionMailer::Base.perform_deliveries = true
ActionMailer::Base.default_url_options[:host] = "test.com"

Rails.backtrace_cleaner.remove_silencers!

# Run any available migration
ActiveRecord::Migrator.migrate File.expand_path("../rails_app/db/migrate/", __FILE__)

require File.expand_path("../../lib/king_views.rb",  __FILE__)
# Load support files
Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  # Remove this line if you don't want RSpec's should and should_not
  # methods or matchers
  require 'rspec/expectations'
  config.include RSpec::Matchers

  # == Mock Framework
  config.mock_with :rspec
end

# define an rspec helper for takes_less_than
require 'benchmark'
RSpec::Matchers.define :take_less_than do |n|
  chain :seconds do; end
  match do |block|
    @elapsed = Benchmark.realtime do
      block.call
    end
    @elapsed <= n
    puts "Took #{@elapsed} seconds"
  end
end



################################################################################
# File related
################################################################################
FIXTURE_PATH = "#{File.dirname(__FILE__)}/fixtures" unless defined?(FIXTURE_PATH)

#open a file in read-mode and return the file object
def load_file(name)
  file_path = File.join(FIXTURE_PATH, "#{name}")
  File.new(file_path, "r")
end
