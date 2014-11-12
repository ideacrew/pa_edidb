require 'rails_helper'

describe NewEnrollment do
  let(:request) { { :individuals => individuals, :policies => policies } }
  let(:listener) { double }
  let(:update_person_use_case) { double(:validate => true) }
  let(:create_policy_use_case) { double(:validate => true) }
  let(:individuals) { [person1] }
  let(:person1) { double }
  let(:policy1) { double }
  let(:policies) { [policy1] }
  before(:each) {
      allow(update_person_use_case).to receive(:validate).with(person1, listener).and_return(true)
      allow(create_policy_use_case).to receive(:validate).with(policy1, listener).and_return(true)
  }

  subject {
    NewEnrollment.new(update_person_use_case, create_policy_use_case)
  }

  it "should notify the listener of success" do
      expect(update_person_use_case).to receive(:commit).with(person1)
      expect(create_policy_use_case).to receive(:commit).with(policy1)
      expect(listener).to receive(:success)
      subject.execute(request, listener)
  end

  describe "with no policies" do
    let(:policies) {
      []
    }

    it "should notify the listener" do
      expect(listener).to receive(:no_policies)
      expect(listener).to receive(:fail)
      subject.execute(request, listener)
    end
  end

  describe "with no individuals" do
    let(:individuals) { [] }
    
    it "should notify the listener" do
      expect(listener).to receive(:no_enrollees)
      expect(listener).to receive(:fail)
      subject.execute(request, listener)
    end
  end

  describe "with an invalid individual" do
    let(:person2) { double }
    let(:individuals) { [person1, person2] }

    before(:each) {
      allow(update_person_use_case).to receive(:validate).with(person2, listener).and_return(false)
    }

    it "should notify the listener of failure" do
      expect(listener).to receive(:fail)
      subject.execute(request, listener)
    end

  end

  describe "with an invalid policy" do
    let(:policy2) { double }
    let(:policies) { [policy1, policy2] }

    before(:each) {
      allow(create_policy_use_case).to receive(:validate).with(policy2, listener).and_return(false)
    }

    it "should notify the listener of failure" do
      expect(listener).to receive(:fail)
      subject.execute(request, listener)
    end

  end
end