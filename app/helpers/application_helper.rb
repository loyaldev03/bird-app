module ApplicationHelper
  
  def controller?(*controller)
    controller.include?(params[:controller])
  end

  def action?(*action)
    action.include?(params[:action])
  end

  def show_svg(path)
    File.open("app/assets/images/#{path}", "rb") do |file|
      raw file.read
    end
  end

  def get_track(track, current_user)
    if current_user && current_user.active_subscription?
      
    end
  end

  def get_setting ident
    setting = SiteSetting.where(ident: ident).first

    setting.val if setting.present?
  end

  def correct_user_path user
    if user.has_role?(:artist)
      return artist_path user
    elsif user.has_role?(:admin)
      return admin_path user
    else
      return user_path user
    end
  end

end
