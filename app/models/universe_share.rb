class UniverseShare < ApplicationRecord
  belongs_to :universe
  belongs_to :user

  enum :permission_level, {
    view: 'view',
    edit: 'edit'
  }

  validates :permission_level, presence: true, inclusion: { in: ['view', 'edit'] }
  validates :user_id, uniqueness: { scope: :universe_id, message: "already has access to this universe" }
  validate :cannot_share_with_owner

  private

  def cannot_share_with_owner
    if universe && user_id == universe.user_id
      errors.add(:user_id, "cannot share universe with its owner")
    end
  end
end
