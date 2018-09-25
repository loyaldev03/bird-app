SLACK = Slack::Notifier.new ENV['SLACK_ORDERS']
SLACK_GENERAL = Slack::Notifier.new ENV['SLACK_GENERAL']