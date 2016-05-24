# frozen_string_literal: true

require "kapost_deploy/slack/notifier"

module KapostDeploy
  module Plugins
    # After-promotion plugin to notify via slack after a promotion is complete with an
    # optional message.
    class SlackAfterPromote
      def initialize(config,
                     notifier: KapostDeploy::Slack::Notifier.new(config.options.fetch(:slack_config, nil)))
        self.config = config
        self.notifier = notifier
      end

      def before
      end

      def after
        return unless notifier.configured?

        message = "#{identity} promoted *#{config.app}* to *#{config.to}*#{additional_message}"
        notifier.notify(message)
      end

      private

      def additional_message
        slack_config = config.options.fetch(:slack_config)
        addl = ""
        addl = slack_config.fetch(:additional_message, "") unless slack_config.nil?
        addl = "\n#{addl}" unless addl.empty?
        addl
      end

      def identity
        @identity ||= `whoami`.chomp
      end

      attr_accessor :notifier

      attr_accessor :config

      attr_accessor :slack_config
    end
  end
end
