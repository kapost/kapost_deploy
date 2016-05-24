# frozen_string_literal: true

require "bundler"
require "English"

module KapostDeploy
  module Heroku
    # Wraps the heroku shell environment
    # Derived from https://github.com/fastestforward/heroku_san
    class Shell
      def initialize(app)
        self.app = app
      end

      def run(command)
        sh("run " + command)
      end

      def sh(command)
        preflight_check_for_cli

        cmd = command.split(" ")
        cmd += ["--app", app]
        cmd << "--exit-code" if command =~ /^run/

        show_command = cmd.join(" ")
        ok = ::Bundler.with_clean_env { system "heroku", *cmd }

        ok or fail "Command failed with status (#{$CHILD_STATUS.exitstatus}): [heroku #{show_command}]"
      end

      private

      attr_accessor :app

      def preflight_check_for_cli
        if Bundler.with_clean_env { system("heroku version").nil? }
          fail "The Heroku Toolbelt is required for this action. http://toolbelt.heroku.com"
        end
      end
    end
  end
end
