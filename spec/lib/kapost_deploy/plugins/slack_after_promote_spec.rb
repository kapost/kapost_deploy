# frozen_string_literal: true
require "spec_helper"
require "kapost_deploy/plugins/slack_after_promote"

RSpec.describe KapostDeploy::Plugins::SlackAfterPromote do
  let(:notifier_double) { double("notifier", notify: true, configured?: true) }

  let(:config) do
    KapostDeploy::Task.define(:slackable) do |config|
      config.app = "scaryskulls-democ"
      config.to = "scaryskulls-prodc"
      config.heroku_api_token = "123"
      config.pipeline = "scaryskulls"

      config.options = { slack_config: slack_config }
    end
  end

  subject { described_class.new(config, notifier: notifier_double) }

  before do
    allow(subject).to receive(:identity).and_return("brandonc")
  end

  let(:slack_config) do
    {
      webhook_url: "https://daredevil.kapost.com",
      additional_message: "additional!"
    }
  end

  it "notifies slack after promote" do
    subject.after
    msg = "brandonc promoted *scaryskulls-democ* to *scaryskulls-prodc*\nadditional!"
    expect(notifier_double).to have_received(:notify).with(msg)
  end

  context "not configured" do
    let(:notifier_double) { double("notifier", notify: true, configured?: false) }

    it "does nothing" do
      subject.after
      expect(notifier_double).to_not have_received(:notify)
    end
  end
end
