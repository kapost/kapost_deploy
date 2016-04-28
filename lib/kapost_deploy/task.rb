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
      define_hooks

      desc "Promote #{app} to #{to.join(",")}"
      task name.to_s do
        shell("heroku plugins:install heroku-pipelines") unless pipelines_installed?
        @before.call
        promote
        @after.call
      end
    end

    private

    def shell(command)
      @shell.call(command)
    end

    def pipelines_installed?
      `heroku plugins` =~ /^heroku-pipelines@/
    end

    def define_hooks
      namespace :"#{name}" do
        desc "Perform after-#{name} tasks"
        task :"after_#{name}" do
          @after.call
        end

        desc "Perform before-#{name} tasks"
        task :"before_#{name}" do
          @before.call
        end
      end
    end

    def promote
      shell("heroku pipelines:promote -a #{app} --to #{to.join(",")}")
    end
  end
end
