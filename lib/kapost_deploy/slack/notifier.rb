# frozen_string_literal: true

require "slack-notify"

module KapostDeploy
  module Slack
    # Wrapper for slack-notify gem
    class Notifier
      def initialize(slack_config)
        self.slack_config = slack_config
      end

      def notify(message)
        return unless configured?
        slack.notify(message)
      end

      def configured?
        !slack_config.nil?
      end

      private

      def slack
        @slack ||= SlackNotify::Client.new(slack_config)
      end

      attr_accessor :slack_config
    end
  end
end
