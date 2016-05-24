# frozen_string_literal: true

require "platform-api"

module KapostDeploy
  module Heroku
    # Promotes a heroku app via Heroku Plaform API
    class AppReleases
      def initialize(app, token:)
        self.app = app
        self.token = token
      end

      def latest_deploy_version
        # This appears to be conventional for pipelines and standard heroku deploys and not a
        # good way to get the deployed git version.
        list.each do |item|
          return Regexp.last_match[:sha1] if item["description"] =~ /^Deploy (?<sha1>[a-f0-9]+)$/
        end
        nil
      end

      def list
        heroku.release.list(app)
      end

      private

      attr_accessor :app
      attr_accessor :token

      def heroku
        @heroku ||= PlatformAPI.connect(token, default_headers: { "Range" => "version ..; order=desc" })
      end
    end
  end
end
