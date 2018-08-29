namespace :braintree do
  desc 'Refreshes Subscription Expiration Dates'
  task subscription_refresh: :environment do
    User.all.each do |user|
      user.active_subscription?

      if user.subscription_started_at.day == Date.today.day &&
         ( user.subscription_length == 'monthly_8_25' ||
           user.subscription_length == 'yearly_99' ||
           user.subscription_length == 'monthly_old' )
        user.increment!(:download_credits, 10)
      end
    end
  end
end
