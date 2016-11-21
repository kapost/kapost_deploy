# frozen_string_literal: true

require "rake"
require "rake/tasklib"
require "kapost_deploy/heroku/app_promoter"
require "kapost_deploy/plugins/validate_before_promote"

module KapostDeploy
  ##
  # Simple Example:
  #
  #   require 'kapost_deploy/task'
  #
  #   KapostDeploy::Task.define do |config|
  #     config.pipeline = 'cabbage'
  #     config.heroku_api_token = ENV.fetch('HEROKU_API_TOKEN')
  #     config.app = 'cabbage-democ'
  #     config.to = 'cabbage-prodc'
  #
  #     config.after do
  #       puts "It's Miller time"
  #     end
  #   end
  #
  class Task < Rake::TaskLib
    attr_accessor :app

    attr_accessor :to

    attr_accessor :pipeline

    attr_accessor :heroku_api_token

    attr_accessor :name

    attr_accessor :options

    def self.define(name = :promote) # :yield: self
      instance = new(name)

      yield instance if block_given?

      instance.validate
      instance.define
      instance.add_plugin(KapostDeploy::Plugins::ValidateBeforePromote)
      instance
    end

    def before(&block)
      @before = block
    end

    def after(&block)
      @after = block
    end

    def add_plugin(plugin)
      plugins << plugin
    end

    def defaults
      @name = :promote
      @pipeline = nil
      @heroku_api_token = ENV["HEROKU_DEPLOY_API_TOKEN"]
      @app = nil
      @to = nil
      @before = -> {}
      @after = -> {}
      @plugins = []
      @options = {}
    end

    def validate
      fail "No 'pipeline' configured. Set config.pipeline to the name of your pipeline" if pipeline.nil?
      fail "No 'app' configured. Set config.app to the application to be promoted" if app.nil?
      fail "No 'to' configured. Set config.to to the downstream application to be promoted to" if to.nil?
    end

    def define
      define_hooks

      desc "Promote #{app} to #{to}"
      task name.to_s do
        promote_with_hooks
      end
    end

    private

    def initialize(name, scope: Rake.application.current_scope.path)
      defaults
      @name = name
      @scope = scope
    end

    attr_accessor :plugins
    attr_reader :scope

    def hook_name(type)
      return "#{name}:#{type}_#{name}" if scope.empty?
      "#{scope}:#{name}:#{type}_#{name}"
    end

    def promoter
      fail "`HEROKU_DEPLOY_API_TOKEN` env var must be provided" unless heroku_api_token
      @promoter ||= KapostDeploy::Heroku::AppPromoter.new(pipeline, token: heroku_api_token)
    end

    def promote_with_hooks
      Rake.application[hook_name("before")].execute
      promoter.promote(from: app, to: to)
      Rake.application[hook_name("after")].execute
    end

    def shell(command)
      @shell.call(command)
    end

    def define_hooks
      namespace :"#{name}" do
        define_hook(:before)
        define_hook(:after)
      end
    end

    def define_hook(kind)
      desc "Perform #{kind}-#{name} tasks"
      task :"#{kind}_#{name}" do
        instance_variable_get(:"@#{kind}").call
        plugins.each do |p|
          plugin = p.new(self)
          plugin.send(kind) if plugin.respond_to?(kind)
        end
      end
    end
  end
end
