# frozen_string_literal: true

require "bundler/setup"

if ENV["CI"]
  require "simplecov"
  SimpleCov.start
end

require "kapost_deploy"

Dir[File.join(File.dirname(__FILE__), "support/extensions/**/*.rb")].each { |file| require file }
Dir[File.join(File.dirname(__FILE__), "support/kit/**/*.rb")].each { |file| require file }
