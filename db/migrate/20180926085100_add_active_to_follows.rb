class AddActiveToFollows < ActiveRecord::Migration[5.1]
  def change
    add_column :follows, :active, :boolean, default: false
  end
end
