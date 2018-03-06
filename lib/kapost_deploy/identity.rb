# frozen_string_literal: true

module KapostDeploy
  # Gem identity information.
  module Identity
    def self.name
      "kapost_deploy"
    end

    def self.label
      "KapostDeploy"
    end

    def self.version
      "0.6.2"
    end

    def self.version_label
      "#{label} #{version}"
    end
  end
end
