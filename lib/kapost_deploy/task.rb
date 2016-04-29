require "rake"
require "rake/tasklib"

module KapostDeploy
  ##
  # Simple Example:
  #
  #   require 'kapost_deploy/task'
  #
  #   KapostDeploy::Task.new do |config|
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
  #     config.app = 'cabbage-stagingc'
  #     config.to = %w[cabbage-sandboxc cabbage-democ]
  #
  #     config.after do
  #       sleep 60*2 # wait for dynos to restart
  #       notifier.ping "The eagle has landed. [Go validate](https://testbed.sandbox.com/dashboard)!"
  #       Launchy.open("https://testbed.sandbox.com/dashboard")
  #     end
  #   end
  #
  #   KapostDeploy::Task.new(:promote) do |config|
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

    attr_reader :to

    attr_accessor :name

    def initialize(name = :promote, shell: method(:sh)) # :yield: self
      defaults
      @name = name
      @shell = shell

      yield self if block_given?

      validate
      define
    end

    def before(&block)
      @before = block
    end

    def after(&block)
      @after = block
    end

    def to=(to)
      @to = Array(to)
    end

    def add_plugin(plugin)
      plugins << plugin
    end

    def defaults
      @name = :promote
      @app = nil
      @slack_config = nil
      @to = []
      @before = -> {}
      @after = -> {}
      @plugins = []
    end

    def validate
      fail "No 'app' configured. Set config.app to the application to be promoted" if app.nil?
      fail "No 'to' configured. Set config.to to the downstream application(s) to be promoted to" if to.empty?
    end

    def define
      define_hooks

      desc "Promote #{app} to #{to.join(",")}"
      task name.to_s do
        shell("heroku plugins:install heroku-pipelines") unless pipelines_installed?
        promote_with_hooks
      end
    end

    private

    attr_accessor :plugins

    def promote_with_hooks
      Rake.application[:"#{name}:before_#{name}"].execute
      promote
      Rake.application[:"#{name}:after_#{name}"].execute
    end

    def shell(command)
      @shell.call(command)
    end

    def pipelines_installed?
      `heroku plugins` =~ /^heroku-pipelines@/
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

    def promote
      shell("heroku pipelines:promote -a #{app} --to #{to.join(",")}")
    end
  end
end
