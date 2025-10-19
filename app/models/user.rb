class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable
  # Only using :omniauthable for SSO authentication
  devise :database_authenticatable, :rememberable, :omniauthable, omniauth_providers: [:google_oauth2]

  has_many :stories, dependent: :destroy
  has_many :universes, dependent: :destroy
  has_one :mana_prompt, dependent: :destroy
  has_many :universe_shares, dependent: :destroy
  has_many :shared_universes, through: :universe_shares, source: :universe

  validates :name, presence: true
  validates :email, presence: true, uniqueness: true
  validate :must_have_mana_prompt

  after_create :create_default_mana_prompt

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

  private

  def create_default_mana_prompt
    create_mana_prompt!(content: ManaPrompt::DEFAULT_PROMPT)
  end

  def must_have_mana_prompt
    errors.add(:base, "User must have a ManaPrompt") if persisted? && mana_prompt.nil?
  end
end