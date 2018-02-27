# frozen_string_literal: true

require "spec_helper"

require "kapost_deploy/seismograph/notifier"

RSpec.describe KapostDeploy::Seismograph::Notifier do
  context "when seismograph is available" do
    let(:sensor) { instance_spy Seismograph::Sensor }

    subject { described_class.new }

    before do
      require "seismograph"

      allow(Seismograph::Sensor).to receive(:new).and_return(sensor)
    end

    describe "#timing" do
      it "forwards to sensor" do
        subject.timing("deploy", 1, ["a:A", "b:B"])
        expect(sensor).to have_received(:timing).with("deploy", 1, ["a:A", "b:B"])
      end
    end

    describe "#info" do
      before { allow(Seismograph::Log).to receive(:info) }

      it "forwards to logger" do
        msg = "Deployed foo-bar"
        subject.info(msg)
        expect(Seismograph::Log).to have_received(:info).with(msg)
      end
    end
  end

  context "when seismograph is not available" do
    subject { described_class.new }

    before do
      allow(KapostDeploy::Seismograph)
        .to receive(:require)
        .with("seismograph")
        .and_raise(LoadError, "cannot load such file -- seismograph")
    end

    describe "#timing" do
      it "does not raise exception" do
        expect { subject.timing("deploy", 1, ["a:A", "b:B"]) }.not_to raise_exception
      end
    end

    describe "#info" do
      it "does not raise exception" do
        expect { subject.info("Deployed foo-bar") }.not_to raise_exception
      end
    end
  end
end
