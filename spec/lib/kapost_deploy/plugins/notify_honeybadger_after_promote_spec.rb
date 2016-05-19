# frozen_string_literal: true

require "spec_helper"
require "kapost_deploy/plugins/notify_honeybadger_after_promote"

RSpec.describe KapostDeploy::Plugins::NotifyHoneyBadgerAfterPromote do
  let(:git_config) { { github_repo: "kapost/kapost_deploy", path: "." } }
  let(:ahead_releases_double) { double("ahead releases", latest_deploy_version: "1234abc") }

  subject { described_class.new(config, ahead_releases: ahead_releases_double) }

  let(:config) do
    KapostDeploy::Task.define(:test) do |config|
      config.app = "scaryskulls-democ"
      config.to = "scaryskulls-prodc"
      config.pipeline = "scaryskulls"
      config.heroku_api_token = "123"

      config.options = { git_config: git_config }
    end
  end

  it "notifies honeybadger after promote" do
    expect(subject)
      .to receive(:system)
      .with("bundle exec honeybadger deploy -e prodc -s 1234abc -r https://github.com/kapost/kapost_deploy")

    subject.after
  end
end
