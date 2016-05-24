# frozen_string_literal: true

require "spec_helper"

RSpec.describe KapostDeploy::Task do
  after do
    Rake.application = Rake::Application.new
  end

  before do
    allow(subject).to receive(:promoter).and_return(promoter_double)
  end

  subject do
    described_class.define(name) do |config|
      config.app = "scaryskulls-democ"
      config.to = "scaryskulls-prodc"
      config.pipeline = "scaryskulls"
      config.heroku_api_token = "123"

      config.before do
        hook_spy.before
      end

      config.after do
        hook_spy.after
      end

      plugins.each { |p| config.add_plugin(p) }
    end
  end

  let(:name) { :promote }
  let(:hook_spy) { double("hook spies", before: true, after: true) }
  let(:promoter_double) { double("promoter", promote: true) }
  let(:plugins) { [] }

  shared_examples_for "a task definer" do
    it "creates named task" do
      expect(Rake.application[name]).to be_a(Rake::Task)
    end

    it "creates 'before_<name>' task" do
      expect(Rake.application["#{name}:before_#{name}"]).to be_a(Rake::Task)
    end

    it "creates 'after_<name>' task" do
      expect(Rake.application["#{name}:after_#{name}"]).to be_a(Rake::Task)
    end
  end

  shared_examples_for "a hook invoker" do
    it "calls before hook" do
      Rake::Task[name].execute
      expect(hook_spy).to have_received(:before).once
    end

    it "calls after hook" do
      Rake::Task[name].execute
      expect(hook_spy).to have_received(:after).once
    end

    context "when before_<name> hook is invoked" do
      it "calls only before hook" do
        Rake::Task["#{name}:before_#{name}"].execute
        expect(hook_spy).to have_received(:before).once
        expect(promoter_double).to_not have_received(:promote)
      end
    end

    context "when after_<name> hook is invoked" do
      it "calls only before hook" do
        Rake::Task["#{name}:after_#{name}"].execute
        expect(hook_spy).to have_received(:after).once
        expect(hook_spy).to_not have_received(:before)
        expect(promoter_double).to_not have_received(:promote)
      end
    end
  end

  shared_examples_for "a promote command" do
    it "promotes to production" do
      Rake::Task[name].execute
      expect(promoter_double).to have_received(:promote).with(from: "scaryskulls-democ", to: "scaryskulls-prodc").once
    end
  end

  shared_examples_for "a plugin invoker" do
    let(:plugin_double) { double("plugin", before: true, after: true) }
    let(:plugin_class_double) { double("plugin class", new: plugin_double) }

    context "when plugins are present" do
      let(:plugins) { [plugin_class_double, plugin_class_double] }

      it "invokes each plugins' before/after hooks" do
        Rake::Task[name].execute
        expect(plugin_double).to have_received(:before).twice
        expect(plugin_double).to have_received(:after).twice
      end
    end
  end

  it_behaves_like "a task definer"
  it_behaves_like "a hook invoker"
  it_behaves_like "a promote command"
  it_behaves_like "a plugin invoker"

  context "customized name" do
    let(:name) { :gobbledigook }

    it_behaves_like "a task definer"
    it_behaves_like "a hook invoker"
    it_behaves_like "a promote command"
    it_behaves_like "a plugin invoker"
  end
end
