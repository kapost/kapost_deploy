require "rake"
require "rake/tasklib"

module KapostDeploy
  ##
  # KapostDeploy::Task creates the following rake tasks to aid in the promotion deployment of
  # standard heroku applications (usually provisioned using
  # https://github.com/kapost/heroku-cabbage)
  #
  # [promote]
  #   Promotes a source envirnment to production
  #
  # [before_promote]
  #   Executes application-defined before promotion code as defined in task config (See below)
  #
  # [after_promote]
  #   Executes application-defined after promotion code as defined in task config (See below)
  #
  # Simple Example:
  #
  #   require 'kapost_deploy/task'
  #
  #   KapostDeploy::Task.define do |config|
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

    def self.define(name = :promote, shell: method(:sh)) # :yield: self
      instance = new(name, shell)

      yield instance if block_given?

      instance.validate
      instance.define
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

    def defaults
      @name = :promote
      @app = nil
      @to = []
      @before = -> {}
      @after = -> {}
    end

    def validate
      fail "No 'app' configured. Set config.app to the application to be promoted" if app.nil?
      fail "No 'to' configured. Set config.to to the downstream application(s) to be promoted to" if to.empty?
    end

    def define
      define_dependencies
      define_hooks

      desc "Promote application to production environment"
      task name.to_s => :install_pipelines do
        @before.call
        promote
        @after.call
      end
    end

    private

    def initialize(name, shell)
      defaults
      @name = name
      @shell = shell
    end

    def shell(command)
      @shell.call(command)
    end

    def define_dependencies
      desc "Install heroku pipelines addon if necessary"
      task :install_pipelines do
        shell("heroku plugins:install heroku-pipelines") unless pipelines_installed?
      end
    end

    def pipelines_installed?
      `heroku plugins` =~ /^heroku-pipelines@/
    end

    def define_hooks
      desc "Perform after-promotion tasks"
      task :"after_#{name}" do
        @after.call
      end

      desc "Perform before-promotion tasks"
      task :"before_#{name}" do
        @before.call
      end
    end

    def promote
      shell("heroku pipelines:promote -a #{app} --to #{to.join(",")}")
    end
  end
end
