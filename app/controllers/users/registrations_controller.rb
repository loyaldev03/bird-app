class Users::RegistrationsController < Devise::RegistrationsController
  before_action :set_notifications#, only: [:edit]

  protected

  def after_sign_up_path_for(resource)
    choose_profile_path
  end

  def update_resource(resource, params)
    if resource.provider.present?
      resource.update_without_password(params) 
    else
      resource.update_with_password(params)
    end
  end
end