class Users::RegistrationsController < Devise::RegistrationsController
  before_action :set_notifications#, only: [:edit]

  protected

  def after_sign_up_path_for(resource)
    choose_profile_path(anchor: 'step-2')
  end

  def update_resource(resource, params)
    debugger
    resource.update_without_password(params) 
    # if resource.provider.present?
    #   resource.update_without_password(params) 
    # else
    #   resource.update_with_password(params)
    # end
  end

  # private

  # def account_update_params
  #   params.require(:user).permit(:first_name, :last_name, :email, :password, :password_confirmation, :current_password, :profile_url)
  # end

end