# frozen_string_literal: true

require "spec_helper"
require "rake"

RSpec.describe KapostDeploy, :integration do
  include ::Rake::DSL

  let(:task_names) { Rake.application.tasks.map { |task| task.name.to_s } }
  let :deploy_task do
    KapostDeploy::Task.define(:stage) do |config|
      config.app = "test-review"
      config.to = "test-stage"
      config.pipeline = "tester"
    end
  end

  before { Rake::Task.clear }

  context "without namespace" do
    before { deploy_task }

    it "answers namespaces deploy tasks" do
      expect(task_names).to contain_exactly(
        "stage",
        "stage:before_stage",
        "stage:after_stage"
      )
    end
  end

  context "with namespace" do
    before do
      namespace :deploy do
        deploy_task
      end
    end

    it "answers namespaces deploy tasks" do
      expect(task_names).to contain_exactly(
        "deploy:stage",
        "deploy:stage:before_stage",
        "deploy:stage:after_stage"
      )
    end
  end
end
