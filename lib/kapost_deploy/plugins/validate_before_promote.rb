# frozen_string_literal: true

module KapostDeploy
  module Plugins
    # Validates runtime configuration
    class ValidateBeforePromote
      def initialize(config)
        @config = config
      end

      def before
        fail <<~MSG unless @config.heroku_api_token
          No 'heroku_api_token' configured. Set config.heroku_api_token to your
          API secret token (use `heroku auth:token` to get it).
        MSG
      end
    end
  end
end
