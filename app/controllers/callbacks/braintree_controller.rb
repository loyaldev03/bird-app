class Callbacks::BraintreeController < ApplicationController
  protect_from_forgery with: :null_session, only: [:analytics_notify]

  def nonce
    #buy more credits logic
    if params[:credits_count].present?
      unless current_user.braintree_customer
        flash[:error] = 'You should be subscribed first'
        redirect_to choose_profile_path and return
      end

      if params[:payment_method_nonce].present? && current_user.braintree_subscription
        payment_method = Braintree::PaymentMethod.update(
          current_user.braintree_subscription.payment_method_token,
          payment_method_nonce: params[:payment_method_nonce]
        )

        if payment_method.success?
        else
          flash[:error] = 'Failed to update payment method. You cannot currently change from Credit Card to PayPal billing. If you are still having issues, contact support.'
          redirect_to choose_profile_path and return
        end
      end
      
      result = Braintree::Transaction.sale(
        :amount => params[:credits_count].to_f,
        :payment_method_token => current_user.braintree_customer.payment_methods[0].token,
        :options => {
          :submit_for_settlement => true
        }
      )

      if result.success?
        current_user.increment!(:download_credits, params[:credits_count].to_i)

        if payment_method.present?
          flash[:notice] = "#{params[:credits_count]} credits was added"
        else
          flash[:notice] = "Payment method was updated and #{params[:credits_count]} credits was added"
        end
      else
        flash[:error] = 'Error when adding credits. If unexpected, contact support.'
        redirect_to get_more_credits_path and return
      end

      notification = "Order!"
      notification << " #{current_user.try(:name)}(#{current_user.try(:id)})"
      notification << "subscr: #{params[:subscription]}" if params[:subscription].present?
      notification << "subscr: #{params[:credits_count]}" if params[:credits_count].present?
      SLACK.ping notification

      redirect_to get_more_credits_path( success: true ) and return
    end
 
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
      if params[:subscription] == 'yearly_99'
        plan_id = ENV['BRAINTREE_YEARLY_PLAN_99_ID']
        download_credits = 30
      elsif params[:subscription] == 'yearly_75'
        plan_id = ENV['BRAINTREE_YEARLY_PLAN_75_ID']
      elsif params[:subscription] == 'monthly_6_25'
        plan_id = ENV['BRAINTREE_MONTHLY_PLAN_6_25_ID']
      elsif params[:subscription] == 'monthly_8_25'
        plan_id = ENV['BRAINTREE_MONTHLY_PLAN_8_25_ID']  
        download_credits = 30
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
          subscription_length: params[:subscription],
          download_credits: download_credits
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
