# frozen_string_literal: true

require "kapost_deploy/heroku/app_releases"

module KapostDeploy
  module Plugins
    # After-promotion plugin to notify honeybadger after a promotion is complete.
    # Honeybadger.io can be configured to clear all honeybadgers upon this deploy notification.
    class NotifyHoneyBadgerAfterPromote
      def initialize(config,
                     ahead_releases: KapostDeploy::Heroku::AppReleases.new(config.app, token: config.heroku_api_token),
                     kernel: Kernel)

        self.config = config
        self.git_config = config.options.fetch(:git_config, {})
        self.ahead_releases = ahead_releases
        self.kernel = kernel
      end

      def after
        return unless configured?

        notify_honeybadger
      end

      private

      attr_accessor :config, :git_config, :ahead_releases, :kernel

      def notify_honeybadger
        kernel.system("bundle exec honeybadger deploy -e #{env} -s #{commit_sha} -r #{repository_url}")
      end

      def env
        config.to.split("-").last
      end

      def commit_sha
        ci_sha || pipeline_sha
      end

      def ci_sha
        ENV["CIRCLE_SHA1"]
      end

      def pipeline_sha
        ahead_releases.latest_deploy_version
      end

      def github_repo
        git_config[:github_repo] unless git_config.nil?
      end

      def repository_url
        "https://github.com/#{github_repo}"
      end

      def configured?
        !github_repo.nil? && !github_repo.empty?
      end
    end
  end
end
