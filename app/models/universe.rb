class Universe < ApplicationRecord
  belongs_to :user
  has_many :chapters, dependent: :destroy
  has_many :scenes, through: :chapters
  has_many :beats, through: :scenes
  has_many :characters, dependent: :destroy
  has_many :locations, dependent: :destroy

  validates :name, presence: true
end
