class SliderImage < ApplicationRecord
  mount_uploader :image, SliderUploader
  scope :ordered, -> { order(priority: :asc, id: :desc) }
end
