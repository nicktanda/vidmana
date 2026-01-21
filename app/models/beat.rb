class Beat < ApplicationRecord
  belongs_to :universe

  validates :title, presence: true
end
