# frozen_string_literal: true

require "spec_helper"
require "kapost_deploy/plugins/slack_github_diff"

RSpec.describe KapostDeploy::Plugins::SlackGithubDiff do
  let(:notifier_double) { double("notifier", notify: true, configured?: true) }
  let(:git_repo_double) { double("git repo", log: git_log_double) }
  let(:git_log_double) { double("git log", between: [1, 2]) }
  let(:git_config) { { github_repo: "kapost/kapost_deploy", path: "." } }
  let(:ahead_releases_double) { double("ahead releases", latest_deploy_version: "1234abc") }
  let(:behind_releases_double) { double("behind releases", latest_deploy_version: "9876edc") }

  subject do
    described_class.new(config,
                        notifier: notifier_double,
                        ahead_releases: ahead_releases_double,
                        behind_releases: behind_releases_double)
  end

  let(:config) do
    KapostDeploy::Task.define(:slackable) do |config|
      config.app = "scaryskulls-democ"
      config.to = "scaryskulls-prodc"
      config.pipeline = "scaryskulls"
      config.heroku_api_token = "123"

      config.options = { git_config: git_config }
    end
  end

  before do
    allow(subject).to receive(:identity).and_return("brandonc")
  end

  it "notifies with message about commit size" do
    subject.before

    url = "https://github.com/kapost/kapost_deploy/compare/9876edc...1234abc"
    msg = "brandonc is promoting <#{url}|1234abc> from *scaryskulls-democ* to *scaryskulls-prodc*"
    expect(notifier_double).to have_received(:notify).with(msg)
  end

  context "when git not configured" do
    let(:git_config) { nil }

    it "does not notify" do
      subject.before
      expect(notifier_double).to_not have_received(:notify)
    end
  end

  context "when slack not configured" do
    let(:notifier_double) { double("notifier", notify: true, configured?: false) }

    it "does not notify" do
      subject.before
      expect(notifier_double).to_not have_received(:notify)
    end
  end
end
