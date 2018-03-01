class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  
  before_action :set_data_layer

  def set_data_layer
    @data_layer = {}
    @data_layer[:event] = 'tracking'

    @data_layer[:cd3] = 'DataLayer'

    # Setting user id if user logged in
    return unless current_user
    @data_layer[:user_id] = current_user.id
    @data_layer[:subscriber_type] = current_user.subscriber_type
  end
end
