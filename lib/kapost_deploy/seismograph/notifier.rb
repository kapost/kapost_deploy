# frozen_string_literal: true

module KapostDeploy
  module Seismograph
    def self.seismograph_adapter
      require "seismograph"
      ::Seismograph
    rescue LoadError
      NullAdapter
    end

    # Wrapper for seismograph gem
    class Notifier
      extend Forwardable

      def_delegator :sensor, :timing
      def_delegator :logger, :info

      def initialize
        self.adapter = KapostDeploy::Seismograph.seismograph_adapter
      end

      private

      attr_accessor :adapter

      def sensor
        @sensor ||= adapter::Sensor.new(:kapost_deploy)
      end

      def logger
        adapter::Log
      end
    end

    module NullAdapter
      class Sensor
        def initialize(_namespace); end

        def timing(_description, _duration, _params = {}); end
      end

      module Log
        def self.info(_message, _params = {}); end
      end
    end
  end
end
