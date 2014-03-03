module Spree::Chimpy
  class Subscription
    delegate :configured?, :enqueue, to: Spree::Chimpy

    def initialize(user)
      @user      = user
    end

    def subscribe(source = nil)
      chimpy_action = Spree::Chimpy::Action.new(email: @user.email, source: source, action: :subscribe)
      if @user.valid? && !@user.subscribed? && chimpy_action.save
        @user.update_column(:subscribed, true)
        defer(:subscribe)
        true
      else
        false
      end
    end

    def update_member_info
      if @user.subscribed?
        defer(:subscribe)
      end
    end

    def unsubscribe(source = nil)
      chimpy_action = Spree::Chimpy::Action.new(email: @user.email, source: source, action: :unsubscribe)
      if @user.subscribed? && chimpy_action.save
        @user.update_column(:subscribed, false)
        defer(:unsubscribe) 
        true
      else
        false
      end
    end

    def resubscribe(&block)
      block.call if block

      return unless configured?

      if unsubscribing?
        defer(:unsubscribe) 
      elsif @user.subscribed?
        defer(:subscribe)
      end
    end

  private
    def defer(event)
      enqueue(event, @user)
    end

    def subscribing?
      merge_vars_changed? && @user.subscribed
    end

    def unsubscribing?
      !@new_record && !@user.subscribed? && @user.subscribed_changed?
    end

  end
end
