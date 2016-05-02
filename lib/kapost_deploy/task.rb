# frozen_string_literal: true
require "rake"
require "rake/tasklib"
require "kapost_deploy/heroku/app_promoter"

module KapostDeploy
  ##
  # Simple Example:
  #
  #   require 'kapost_deploy/task'
  #
  #   KapostDeploy::Task.new do |config|
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
  # A slightly more complex example which will create 6 rake tasks: before_stage, stage,
  # after_stage, before_promote, promote, after_promote
  #
  #   KapostDeploy::Task.new(:stage) do |config|
  #     config.pipeline = 'cabbage'
  #     config.heroku_api_token = ENV.fetch('HEROKU_API_TOKEN')
  #     config.app = 'cabbage-stagingc'
  #     config.to = 'cabbage-sandboxc'
  #
  #     config.after do
  #       sleep 60*2 # wait for dynos to restart
  #       notifier.ping "The eagle has landed. [Go validate](https://testbed.sandbox.com/dashboard)!"
  #       Launchy.open("https://testbed.sandbox.com/dashboard")
  #     end
  #   end
  #
  #   KapostDeploy::Task.new(:promote) do |config|
  #     config.pipeline = 'cabbage'
  #     config.heroku_api_token = ENV.fetch('HEROKU_API_TOKEN')
  #     config.app = 'cabbage-sandbox1c'
  #     config.to = 'cabbage-prodc'
  #
  #     config.before do
  #       puts 'Are you sure you did x, y, and z? yes/no: '
  #       confirm = gets.strip
  #       exit(1) unless confirm.downcase == 'yes'
  #     end
  #   end
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
      @heroku_api_token = nil
      @app = nil
      @to = nil
      @before = -> {}
      @after = -> {}
      @plugins = []
      @options = {}
    end

    def validate
      fail "No 'heroku_api_token' configured."\
           "Set config.heroku_api_token to your API secret token" if heroku_api_token.nil?
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

    def initialize(name)
      defaults
      self.name = name
    end

    attr_accessor :plugins

    def promoter
      @promoter ||= KapostDeploy::Heroku::AppPromoter.new(pipeline, token: heroku_api_token)
    end

    def promote_with_hooks
      Rake.application[:"#{name}:before_#{name}"].execute
      promoter.promote(from: app, to: to)
      Rake.application[:"#{name}:after_#{name}"].execute
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
