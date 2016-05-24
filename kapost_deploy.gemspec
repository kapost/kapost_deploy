# frozen_string_literal: true
$LOAD_PATH.push File.expand_path("../lib", __FILE__)
require "kapost_deploy/identity"

Gem::Specification.new do |spec|
  spec.name = KapostDeploy::Identity.name
  spec.version = KapostDeploy::Identity.version
  spec.platform = Gem::Platform::RUBY
  spec.authors = ["Brandon Croft"]
  spec.email = ["brandon.croft@gmail.com"]
  spec.homepage = "https://github.com/kapost/kapost_deploy"
  spec.summary = "Deployment rake tasks for Kapost applications"
  spec.description = "Execute deployments swiftly and safely using `rake promote`"
  spec.license = "MIT"

  spec.add_dependency "rake", ">= 10.0"
  spec.add_dependency "platform-api", ">= 0.6.0"
  spec.add_dependency "slack-notify", ">= 0.4.1"
  spec.add_dependency "honeybadger", "~> 2.0"

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "gemsmith", "~> 7.7"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "pry-remote"
  spec.add_development_dependency "pry-state"
  spec.add_development_dependency "pry-rescue"
  spec.add_development_dependency "pry-stack_explorer"
  spec.add_development_dependency "rspec", "~> 3.4"
  spec.add_development_dependency "rb-fsevent" # Guard file events for OSX.
  spec.add_development_dependency "guard-rspec"
  spec.add_development_dependency "terminal-notifier"
  spec.add_development_dependency "terminal-notifier-guard"
  spec.add_development_dependency "rubocop", "~> 0.37"
  spec.add_development_dependency "codeclimate-test-reporter"
  spec.add_development_dependency "rubygems-tasks"
  spec.add_development_dependency "climate_control"

  spec.files = Dir["lib/**/*", "vendor/**/*"]
  spec.extra_rdoc_files = Dir["README*", "LICENSE*"]
  spec.require_paths = ["lib"]
end
