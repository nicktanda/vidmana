class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable, :omniauthable, omniauth_providers: [:google_oauth2]

  has_many :stories, dependent: :destroy

  validates :name, presence: true
  validate :password_strength_validation, if: :password_required?

  # OmniAuth callback handler
  def self.from_omniauth(auth)
    where(email: auth.info.email).first_or_create do |user|
      user.email = auth.info.email
      user.name = auth.info.name
      user.provider = auth.provider
      user.uid = auth.uid
      user.password = Devise.friendly_token[0, 20]
      user.avatar_url = auth.info.image
    end
  end

  private

  def password_strength_validation
    return unless password.present?

    # Check for common weak passwords
    weak_passwords = %w[
      password password123 123456 123456789 qwerty abc123
      password1 admin 12345678 1234567 12345 1234 123
      letmein welcome monkey 1234567890 dragon master
      hello freedom whatever qazwsx trustno1
    ]

    if weak_passwords.include?(password.downcase)
      errors.add(:password, "is too common. Please choose a more secure password.")
      return
    end

    # Check password strength requirements
    unless password.match?(/\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>\/?]).{8,}\z/)
      errors.add(:password, "must be at least 8 characters long and contain at least one uppercase letter, one lowercase letter, one number, and one special character.")
    end

    # Check for repeated characters (more than 3 in a row)
    if password.match?(/(.)\1{3,}/)
      errors.add(:password, "cannot contain more than 3 consecutive identical characters.")
    end

    # Check for sequential characters (like 1234 or abcd)
    if password.match?(/(0123|1234|2345|3456|4567|5678|6789|7890|abcd|bcde|cdef|defg|efgh|fghi|ghij|hijk|ijkl|jklm|klmn|lmno|mnop|nopq|opqr|pqrs|qrst|rstu|stuv|tuvw|uvwx|vwxy|wxyz)/i)
      errors.add(:password, "cannot contain sequential characters.")
    end
  end

  def password_required?
    return false if provider.present? # OAuth users don't need passwords
    new_record? || password.present?
  end
end
