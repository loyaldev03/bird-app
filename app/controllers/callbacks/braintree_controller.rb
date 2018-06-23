class Callbacks::BraintreeController < ApplicationController
  protect_from_forgery with: :null_session, only: [:analytics_notify]

  def nonce
    if params[:payment_method_nonce].blank?
      # Honeybadger.notify(
      #   error_class: 'MissingNonce',
      #   error_message: 'Missing Nonce on Callback',
      #   parameters: params
      # )

      flash[:error] = 'Failed to process payment. Please double check your information and try again. You have not yet been charged.'
      redirect_to choose_profile_path and return
    end

    # Create or find customer
    unless current_user.braintree_customer
      # Create Customer and store their Payment Method
      result = Braintree::Customer.create(
        first_name: current_user.first_name,
        last_name: current_user.last_name,
        email: current_user.email,
        payment_method_nonce: params[:payment_method_nonce]
      )

      if result.success?
        current_user.update(braintree_customer_id: result.customer.id)
      else
        flash[:error] = 'Failed to create new Customer record. If unexpected, contact support.'
        redirect_to choose_profile_path and return
      end
    end

    # Create or find Subscription
    if current_user.braintree_subscription
      result = Braintree::PaymentMethod.update(
        current_user.braintree_subscription.payment_method_token,
        payment_method_nonce: params[:payment_method_nonce]
      )

      if result.success?
        flash[:notice] = 'Payment method updated.'
        redirect_to root_path and return
      else
        flash[:error] = 'Failed to update payment method. You cannot currently change from Credit Card to PayPal billing. If you are still having issues, contact support.'
        redirect_to choose_profile_path and return
      end
    else
      if params[:subscription] == 'yearly'
        plan_id = ENV['BRAINTREE_YEARLY_PLAN_ID']
      elsif params[:subscription] == 'monthly'
        plan_id = ENV['BRAINTREE_MONTHLY_PLAN_ID']
      else
        throw "Couldn't find plan for subscription #{params[:subscription]}"
      end

      result = Braintree::Subscription.create(
        plan_id: plan_id,
        payment_method_token: current_user.braintree_customer.payment_methods[0].token
      )

      if result.success?
        current_user.update!(
          braintree_subscription_id: result.subscription.id,
          subscription_started_at: Date.today,
          subscription_length: params[:subscription]
        )
          # subscribed: true,

        if result.subscription.trial_period
          current_user.update!(braintree_subscription_expires_at: result.subscription.next_billing_date.to_date - 1)
        else
          current_user.update!(braintree_subscription_expires_at: result.subscription.paid_through_date)
        end
      else
        flash[:error] = 'Failed to create new Subscription record. If unexpected, contact support.'
        redirect_to choose_profile_path and return
      end
    end

    flash[:notice] = 'Subscription Created'

    begin
      payment_method = if current_user.braintree_customer.payment_methods.first.respond_to?(:last_4)
                         'credit_card'
                       else
                         'paypal'
                       end
    rescue => e
      # Honeybadger.notify(e)
      # payment_method = 'undetermined'
    end

    redirect_to root_path(event: 'new_subscription', payment: payment_method, type: params[:subscription]) and return
  end

  def analytics_notify
    webhook_notification = Braintree::WebhookNotification.parse(
      params[:bt_signature],
      params[:bt_payload]
    )
    user = User.where(braintree_subscription_id: webhook_notification.subscripption.id).first

    if webhook_notification.kind == Braintree::WebhookNotification::Kind::SubscriptionChargedUnsuccessfully
    elsif webhook_notification.kind == Braintree::WebhookNotification::Kind::SubscriptionChargedSuccessfully
    end
    render body: '', status: 200
  end
end
