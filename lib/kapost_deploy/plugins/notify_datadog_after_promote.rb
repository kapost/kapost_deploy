# frozen_string_literal: true

require "kapost_deploy/heroku/app_releases"
require "kapost_deploy/seismograph/notifier"

module KapostDeploy
  module Plugins
    # Notify Datadog (via seismograph) about deployments by:
    #  - sending deployment timing
    #  - logging an info event
    class NotifyDatadogAfterPromote
      def initialize(config,
                     notifier: KapostDeploy::Seismograph::Notifier.new,
                     ahead_releases: KapostDeploy::Heroku::AppReleases.new(config.app, token: config.heroku_api_token))
        self.config = config
        self.notifier = notifier
        self.ahead_releases = ahead_releases
      end

      def before
        @start_time = Time.now
      end

      def after
        return unless start_time

        notify_datadog
      end

      private

      attr_accessor :config,
                    :notifier,
                    :ahead_releases,
                    :start_time

      def notify_datadog
        time_elapsed = Time.now - start_time

        notifier.timing "deploy", time_elapsed, tags
        notifier.info "Deployed #{github_repo} to #{env}"
      end

      def tags
        [
          "env:#{env}",
          "sha:#{commit_sha}",
          "repository:#{github_repo}"
        ]
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
        config.options.fetch(:git_config).fetch(:github_repo)
      end
    end
  end
end
