require "spec_helper"

RSpec.describe KapostDeploy::Task do
  after do
    Rake.application = Rake::Application.new
  end

  before do
    allow(subject).to receive(:slack).and_return(slack_double)
    allow(subject).to receive(:identity).and_return("brandonc")
    allow(subject).to receive(:pipelines_installed?).and_return(true)
  end

  subject! do
    described_class.new(name, shell: ->(cmd) { command_spy.command(cmd) }) do |config|
      config.app = "scaryskulls-democ"
      config.to = "scaryskulls-prodc"

      config.before do
        hook_spy.before
      end

      config.after do
        hook_spy.after
      end
    end
  end

  let(:name) { :promote }
  let(:hook_spy) { double("hook spies", before: true, after: true) }
  let(:command_spy) { double("command_spy", command: true) }
  let(:slack_double) { double("slack", notify: true) }

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
        expect(command_spy).to_not have_received(:command)
      end
    end

    context "when after_<name> hook is invoked" do
      it "calls only before hook" do
        Rake::Task["#{name}:after_#{name}"].execute
        expect(hook_spy).to have_received(:after).once
        expect(hook_spy).to_not have_received(:before)
        expect(command_spy).to_not have_received(:command)
      end
    end
  end

  shared_examples_for "a promote command" do
    let(:expected_command) { "heroku pipelines:promote -a scaryskulls-democ --to scaryskulls-prodc" }
    it "promotes to production" do
      Rake::Task[name].execute
      expect(command_spy).to have_received(:command).with(expected_command).once
    end
  end

  shared_examples_for "a slack notifier" do
    it "notifies slack after promote" do
      Rake::Task[name].execute
      msg = "brandonc promoted *scaryskulls-democ* to *scaryskulls-prodc*\nadditional!"
      expect(slack_double).to have_received(:notify).with(msg)
    end
  end

  it_behaves_like "a task definer"
  it_behaves_like "a hook invoker"
  it_behaves_like "a promote command"

  context "customized name" do
    let(:name) { :gobbledigook }

    it_behaves_like "a task definer"
    it_behaves_like "a hook invoker"
    it_behaves_like "a promote command"
  end

  context "slack config present" do
    subject! do
      described_class.new(name, shell: ->(cmd) { command_spy.command(cmd) }) do |config|
        config.app = "scaryskulls-democ"
        config.to = "scaryskulls-prodc"

        config.slack_config = {
          webhook_url: "https://daredevil.kapost.com",
          additional_message: "additional!"
        }
      end
    end

    it_behaves_like "a slack notifier"
  end
end
