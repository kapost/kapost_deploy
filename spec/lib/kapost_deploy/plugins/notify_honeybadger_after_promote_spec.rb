# frozen_string_literal: true

require "spec_helper"
require "climate_control"
require "kapost_deploy/plugins/notify_honeybadger_after_promote"

RSpec.describe KapostDeploy::Plugins::NotifyHoneyBadgerAfterPromote do
  let(:git_config) { { github_repo: "kapost/kapost_deploy", path: "." } }
  let(:ahead_releases_double) { double("ahead releases", latest_deploy_version: "1234abc") }
  let(:kernel) { class_spy(Kernel) }

  subject { described_class.new(config, ahead_releases: ahead_releases_double, kernel: kernel) }

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
    it "notifies honeybadger after promote using pipeline sha" do
      ClimateControl.modify CIRCLE_SHA1: nil do
        subject.after
        expect(kernel)
          .to have_received(:system)
          .with("bundle exec honeybadger deploy -e prodc -s 1234abc -r https://github.com/kapost/kapost_deploy")
      end
    end
  end

  context "when CIRCLE_SHA1 enviroment is available" do
    it "notifies honeybadger after promote using circle sha" do
      ClimateControl.modify CIRCLE_SHA1: "19" do
        subject.after
        expect(kernel)
          .to have_received(:system)
          .with("bundle exec honeybadger deploy -e prodc -s 19 -r https://github.com/kapost/kapost_deploy")
        subject.after
      end
    end
  end

  context "when git is not configured" do
    let(:git_config) { nil }

    it "does not notify" do
      subject.after
      expect(kernel).to_not have_received(:system)
    end
  end
end
