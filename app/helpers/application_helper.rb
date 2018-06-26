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

  def get_metadata url
    page = MetaInspector.new(url)
    { title: page.title, desc: page.description, image: page.images.best }
  end

  def comment_with_meta_data text
    if match = text.match(URI.regexp)
      meta_data = get_metadata(match[0])
      meta_data_html = '<strong>'+meta_data[:title].to_s+'</strong>'
      # meta_data_html += '<br>'+meta_data[:desc].try(:truncate,140).to_s if meta_data[:desc]
      meta_data_html += '<br><img class="feed-image" src="'+meta_data[:image].to_s+'">' if meta_data[:image]
      meta_data_html = '<a href="'+match[0]+'" target="_blank">'+meta_data_html+'</a>'
    end

    text.dup.gsub(URI.regexp, '<a href="\0" target="_blank">\0</a><p>'+meta_data_html.to_s+'</p>')
  end

end
