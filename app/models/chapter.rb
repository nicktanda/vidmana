class Chapter < ApplicationRecord
  belongs_to :universe
  has_many :scenes, dependent: :destroy
  has_many :beats, through: :scenes

  validates :name, presence: true
end
