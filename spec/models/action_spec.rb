require 'spec_helper'

describe Spree::Chimpy::Action do
  context "Validation" do
    it "can be valid" do
      Spree::Chimpy::Action.create(email: 'test@example.com').should be_valid
    end

    it "is invalid without email" do
      Spree::Chimpy::Action.new(email: nil).should_not be_valid
    end

    it "is invalid with bad emails" do
      bad_emails = %w(23stnoesthn @@@stnhoeu.com tnhe@stnhs 0932e@.nte).map do |email|
        Spree::Chimpy::Action.new(email: email, action: :subscribe)
      end
     
      bad_emails.each {|email| email.should be_invalid }
    end

  end


end
