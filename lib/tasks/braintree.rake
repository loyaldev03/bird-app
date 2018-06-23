namespace :braintree do
  desc 'Refreshes Subscription Expiration Dates'
  task subscription_refresh: :environment do
    User.all.each do |user|
      user.active_subscription?
    end
  end
end
