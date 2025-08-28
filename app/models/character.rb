class Character < ApplicationRecord
  belongs_to :story
  
  validates :name, presence: true
end
