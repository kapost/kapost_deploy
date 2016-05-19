# frozen_string_literal: true

require "kapost_deploy/heroku/app_releases"

module KapostDeploy
  module Plugins
    class NotifyHoneyBadgerAfterPromote
      def initialize(config,
                     ahead_releases: KapostDeploy::Heroku::AppReleases.new(config.app, token: config.heroku_api_token))
        self.config = config
        self.git_config = config.options.fetch(:git_config, nil)
        self.ahead_releases = ahead_releases
      end

      def before
      end

      def after
        notify_honeybadger
      end

      private

      attr_accessor :config, :git_config, :ahead_releases

      def notify_honeybadger
        system("bundle exec honeybadger deploy -e #{env} -s #{commit_sha} -r #{repository_url}")
      end

      def env
        config.to.split("-").last
      end

      def commit_sha
        ENV["CIRCLE_BUILD_NUM"] || pipeline_sha
      end

      def pipeline_sha
        ahead_releases.latest_deploy_version
      end

      def repository_url
        "https://github.com/#{git_config[:github_repo]}"
      end
    end
  end
end
