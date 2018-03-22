class User < ApplicationRecord
  mount_uploader :avatar, AvatarUploader
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  rolify

  before_create :set_default_avatar, only: :create

  attr_accessor :subscription
  enum gender: [:female, :male]

  validates :name, presence: true

  has_many :topics
  has_many :comments
  has_many :follows
  has_many :likes

  def followed(user = nil)
    self.follows.where(target: user).first
  end

  private

    def set_default_avatar
      self.remote_avatar_url = Faker::Avatar.image
    end
end
