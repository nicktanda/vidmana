class Beat < ApplicationRecord
  belongs_to :scene

  validates :title, presence: true
end
