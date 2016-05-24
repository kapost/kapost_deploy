# frozen_string_literal: true

require "platform-api"

module KapostDeploy
  module Heroku
    # Promotes a heroku app via Heroku Plaform API
    class AppPromoter
      def initialize(pipeline, token:)
        self.pipeline = pipeline
        self.token = token
      end

      def promote(from:, to:)
        pipeline_id = discover_pipeline(pipeline)["id"]
        from_id = discover_app(from)["id"]
        to_id   = discover_app(to)["id"]

        promotion_data = {
          pipeline: { id: pipeline_id },
          source: { app: { id: from_id } },
          targets: [{ app: { id: to_id } }]
        }

        wait_for_promotion(heroku.pipeline_promotion.create(promotion_data))
      end

      private

      attr_accessor :pipeline
      attr_accessor :token

      def wait_for_promotion(promotion)
        while promotion["status"] == "pending"
          print "."
          sleep 1
          promotion = heroku.pipeline_promotion.info(promotion["id"])
        end
      end

      def discover_pipeline(pipeline)
        heroku.pipeline.info(pipeline)
      end

      def discover_app(app_name)
        heroku.app.info(app_name)
      end

      def heroku
        @heroku ||= PlatformAPI.connect(token)
      end
    end
  end
end
