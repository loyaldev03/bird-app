class AddAlignToSliderImage < ActiveRecord::Migration[5.1]
  def change
    add_column :slider_images, :text, :text
  end
end
