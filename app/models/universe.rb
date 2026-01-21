class Universe < ApplicationRecord
  belongs_to :user
  has_many :chapters, dependent: :destroy
  has_many :beats, dependent: :destroy
  has_many :characters, dependent: :destroy
  has_many :locations, dependent: :destroy
  has_many :universe_shares, dependent: :destroy
  has_many :shared_with_users, through: :universe_shares, source: :user

  validates :name, presence: true

  # Check if a user can view this universe
  def can_view?(user)
    return false unless user
    user.id == user_id || universe_shares.exists?(user_id: user.id)
  end

  # Check if a user can edit this universe
  def can_edit?(user)
    return false unless user
    user.id == user_id || universe_shares.exists?(user_id: user.id, permission_level: 'edit')
  end

  # Check if universe is shared with a specific user
  def shared_with?(user)
    return false unless user
    universe_shares.exists?(user_id: user.id)
  end

  # Get permission level for a user
  def permission_for(user)
    return 'owner' if user && user.id == user_id
    share = universe_shares.find_by(user_id: user&.id)
    share&.permission_level
  end
end
