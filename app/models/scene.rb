class Scene < ApplicationRecord
  belongs_to :chapter
  has_many :beats, dependent: :destroy

  validates :name, presence: true
end
