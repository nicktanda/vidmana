class Location < ApplicationRecord
  belongs_to :story
  
  validates :name, presence: true
end
