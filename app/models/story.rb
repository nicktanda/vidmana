class Story < ApplicationRecord
  belongs_to :user
  has_many :beats, dependent: :destroy
  has_many :characters, dependent: :destroy
  has_many :locations, dependent: :destroy
  
  validates :title, presence: true
end
