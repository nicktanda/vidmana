class Location < ApplicationRecord
  belongs_to :universe

  validates :name, presence: true
end
