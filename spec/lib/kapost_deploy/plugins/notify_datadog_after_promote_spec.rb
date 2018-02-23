# frozen_string_literal: true

require "spec_helper"
require "climate_control"
require "seismograph"
require "kapost_deploy/plugins/notify_datadog_after_promote"
require "kapost_deploy/seismograph/notifier"

RSpec.describe KapostDeploy::Plugins::NotifyDatadogAfterPromote do
  let(:git_config) { { github_repo: "kapost/kapost_deploy", path: "." } }
  let(:ahead_releases_double) { double("ahead releases", latest_deploy_version: "1234abc") }
  let(:notifier) { instance_spy KapostDeploy::Seismograph::Notifier }

  subject do
    described_class.new(config, notifier: notifier, ahead_releases: ahead_releases_double)
  end

  let(:config) do
    KapostDeploy::Task.define(:test) do |config|
      config.app = "scaryskulls-democ"
      config.to = "scaryskulls-prodc"
      config.pipeline = "scaryskulls"
      config.heroku_api_token = "123"

      config.options = { git_config: git_config }
    end
  end

  context "when CIRCLE_SHA1 enviroment is not available" do
    around do |example|
      ClimateControl.modify(CIRCLE_SHA1: nil) do
        example.run
      end
    end

    it "sends timing to datadog using pipeline sha" do
      subject.before
      subject.after
      expect(notifier)
        .to have_received(:timing)
        .with("deploy", kind_of(Numeric), contain_exactly("env:prodc",
                                                          "sha:1234abc",
                                                          "repository:kapost/kapost_deploy"))
    end

    it "logs event to datadog" do
      subject.before
      subject.after
      expect(notifier)
        .to have_received(:info).with("Deployed kapost/kapost_deploy to prodc")
    end
  end

  context "when CIRCLE_SHA1 enviroment is available" do
    around do |example|
      ClimateControl.modify(CIRCLE_SHA1: "19") do
        example.run
      end
    end

    it "notifies honeybadger after promote using circle sha" do
      subject.before
      subject.after
      expect(notifier)
        .to have_received(:timing)
        .with("deploy", kind_of(Numeric), contain_exactly("env:prodc",
                                                          "sha:19",
                                                          "repository:kapost/kapost_deploy"))
    end

    it "logs event to datadog" do
      subject.before
      subject.after
      expect(notifier)
        .to have_received(:info).with("Deployed kapost/kapost_deploy to prodc")
    end
  end
end
