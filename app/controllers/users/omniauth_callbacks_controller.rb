class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController

  def facebook
    @user = User.from_omniauth(request.env["omniauth.auth"])

    if @user.persisted?
      sign_in_and_redirect @user
    else
      session["devise.facebook_data"] = request.env["omniauth.auth"].select { |k, v| k == "email" }
      redirect_to choose_profile_path
    end
  end
  
  def google_oauth2
    @user = User.from_omniauth(request.env["omniauth.auth"])


    if @user.persisted?
      sign_in_and_redirect @user
    else
      session["devise.google_data"] = request.env["omniauth.auth"].select { |k, v| k == "email" }
      redirect_to choose_profile_path
    end
  end

  def failure
    redirect_to root_path
  end
  
end
