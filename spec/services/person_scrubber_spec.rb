require 'rails_helper'

describe PersonScrubber, :dbclean => :after_each do
  let(:person) { FactoryGirl.create :person }

  subject { PersonScrubber.scrub(person.id) }

  it "changes the person's first_name" do
    expect { subject }.to change { person.reload.name_first }
  end

  it "changes the person's last_name" do
    expect { subject }.to change { person.reload.name_last }
  end

  it "changes the person's member's dob" do
    expect { subject }.to change { person.reload.members.map(&:dob) }
  end

  it "changes the person's member's ssn" do
    expect { subject }.to change { person.reload.members.map(&:ssn) }
  end

  it "changes the person's phone numbers" do
    expect { subject }.to change { person.reload.phones.map(&:phone_number) }
  end

  it "changes the person's addresses" do
    expect { subject }.to change { person.reload.addresses.map(&:full_address) }
  end

  it "changes the person's email addresses" do
    expect { subject }.to change { person.reload.emails.map(&:email_address) }
  end
end
