class Beat < ApplicationRecord
  belongs_to :story
  
  validates :title, presence: true
  validates :description, presence: true
end
