# frozen_string_literal: true
require "kapost_deploy/heroku/shell"

module KapostDeploy
  module Plugins
    # After-promotion task to run rake db:migrate
    class DbMigrate
      def initialize(config,
                     shell: KapostDeploy::Heroku::Shell.new(config.to))
        self.shell = shell
      end

      def before
      end

      def after
        shell.run("rake db:migrate")
      end

      private

      attr_accessor :shell
    end
  end
end
