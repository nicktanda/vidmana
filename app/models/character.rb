class Character < ApplicationRecord
  belongs_to :universe
  has_one_attached :icon

  validates :name, presence: true
end
