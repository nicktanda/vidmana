class Story < ApplicationRecord
  belongs_to :user
  has_many :beats, dependent: :destroy
  has_many :characters, dependent: :destroy
  has_many :locations, dependent: :destroy

  accepts_nested_attributes_for :characters, allow_destroy: true
  accepts_nested_attributes_for :locations, allow_destroy: true
  accepts_nested_attributes_for :beats, allow_destroy: true
end
