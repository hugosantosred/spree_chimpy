require 'spec_helper'

describe Spree::Chimpy::Interface::Orders do
  let(:interface) { Spree::Chimpy::Interface::Orders.new }
  let(:api)       { double('api', ecomm: double) }
  let(:order)     { FactoryGirl.build(:completed_order_with_totals) }
  let(:true_response) { {"complete" => true } }

  before do
    Spree::Chimpy.stub(:api).and_return(api)
    # we need to have a saved order in order to have a non-nil order number
    # we need to stub :notify_mail_chimp otherwise sync will be called on the order on update!
    order.stub(:notify_mail_chimp).and_return(true_response)
    order.save
  end

  it "adds an order" do
    Spree::Config.site_name = "Super Store"
    Spree::Chimpy::Config.store_id = "super-store"

    api.ecomm.should_receive(:order_add) { |h| h[:id].should == order.number }.and_return(true_response)

    interface.add(order).should be_true
  end

  it "removes an order" do
    Spree::Chimpy::Config.store_id = "super-store"
    api.ecomm.should_receive(:order_del).with('super-store', order.number).and_return(true_response)

    interface.remove(order).should be_true
  end
end
