class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable
  # Only using :omniauthable for SSO authentication
  devise :database_authenticatable, :rememberable, :omniauthable, omniauth_providers: [:google_oauth2]

  has_many :stories, dependent: :destroy

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true

  # OmniAuth callback handler
  def self.from_omniauth(auth)
    where(email: auth.info.email).first_or_create do |user|
      user.email = auth.info.email
      user.name = auth.info.name
      user.provider = auth.provider
      user.uid = auth.uid
      user.avatar_url = auth.info.image
    end
  end
end