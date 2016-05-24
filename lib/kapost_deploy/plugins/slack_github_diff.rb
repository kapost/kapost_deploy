# frozen_string_literal: true

require "kapost_deploy/slack/notifier"
require "kapost_deploy/heroku/app_releases"

module KapostDeploy
  module Plugins
    # Before-promotion plugin to notify slack with a github comparison warning
    class SlackGithubDiff
      def initialize(config,
                     notifier: KapostDeploy::Slack::Notifier.new(config.options.fetch(:slack_config, nil)),
                     behind_releases: KapostDeploy::Heroku::AppReleases.new(config.to, token: config.heroku_api_token),
                     ahead_releases: KapostDeploy::Heroku::AppReleases.new(config.app, token: config.heroku_api_token))

        self.ahead_app = config.app
        self.behind_app = config.to
        self.git_config = config.options.fetch(:git_config, nil)
        self.notifier = notifier
        self.behind_releases = behind_releases
        self.ahead_releases = ahead_releases
      end

      def before
        return unless configured?

        msg = "#{identity} is promoting <#{github_compare_url}|#{ahead_sha1}>"\
              " from *#{ahead_app}* to *#{behind_app}*"

        notifier.notify(msg)
      end

      def after
      end

      private

      attr_accessor :notifier
      attr_accessor :git_config
      attr_accessor :behind_releases
      attr_accessor :ahead_releases
      attr_accessor :ahead_app
      attr_accessor :behind_app

      def behind_sha1
        @behind_sha1 ||= behind_releases.latest_deploy_version
      end

      def ahead_sha1
        @ahead_sha1 ||= ahead_releases.latest_deploy_version
      end

      def identity
        @identity ||= `whoami`.chomp
      end

      def configured?
        !git_config.nil? && notifier.configured?
      end

      def github_compare_url
        "https://github.com/#{git_config[:github_repo]}/compare/#{behind_sha1}...#{ahead_sha1}"
      end
    end
  end
end
