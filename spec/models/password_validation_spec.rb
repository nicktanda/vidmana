require 'rails_helper'

RSpec.describe "Password Validation Logic", type: :model do
  let(:user) { build(:user) }

  describe "weak password detection" do
    let(:weak_passwords) do
      %w[
        password password123 123456 123456789 qwerty abc123
        password1 admin 12345678 1234567 12345 1234 123
        letmein welcome monkey 1234567890 dragon master
        hello freedom whatever qazwsx trustno1
      ]
    end

    it "detects all weak passwords" do
      weak_passwords.each do |weak_password|
        user.password = weak_password
        user.password_confirmation = weak_password
        expect(user).not_to be_valid
        expect(user.errors[:password]).to include('is too common. Please choose a more secure password.')
      end
    end

    it "is case insensitive for weak password detection" do
      user.password = "PASSWORD"
      user.password_confirmation = "PASSWORD"
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include('is too common. Please choose a more secure password.')
    end

    it "accepts passwords not in weak list" do
      user.password = "MyCustomPassword123!"
      user.password_confirmation = "MyCustomPassword123!"
      expect(user).to be_valid
    end
  end

  describe "password strength requirements" do
    it "requires at least 8 characters" do
      user.password = "Pass1!"
      user.password_confirmation = "Pass1!"
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include('must be at least 8 characters long and contain at least one uppercase letter, one lowercase letter, one number, and one special character.')
    end

    it "requires uppercase letter" do
      user.password = "password123!"
      user.password_confirmation = "password123!"
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include('must be at least 8 characters long and contain at least one uppercase letter, one lowercase letter, one number, and one special character.')
    end

    it "requires lowercase letter" do
      user.password = "PASSWORD123!"
      user.password_confirmation = "PASSWORD123!"
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include('must be at least 8 characters long and contain at least one uppercase letter, one lowercase letter, one number, and one special character.')
    end

    it "requires number" do
      user.password = "Password!"
      user.password_confirmation = "Password!"
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include('must be at least 8 characters long and contain at least one uppercase letter, one lowercase letter, one number, and one special character.')
    end

    it "requires special character" do
      user.password = "Password123"
      user.password_confirmation = "Password123"
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include('is too common. Please choose a more secure password.')
    end

    it "requires special character (not in weak list)" do
      user.password = "MyPassword123"
      user.password_confirmation = "MyPassword123"
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include('must be at least 8 characters long and contain at least one uppercase letter, one lowercase letter, one number, and one special character.')
    end

    it "accepts password with all required character types" do
      user.password = "Password123!"
      user.password_confirmation = "Password123!"
      expect(user).to be_valid
    end
  end

  describe "consecutive identical characters" do
    it "rejects password with 4 or more consecutive identical characters" do
      user.password = "Password1111!"
      user.password_confirmation = "Password1111!"
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include('cannot contain more than 3 consecutive identical characters.')
    end

    it "rejects password with 5 or more consecutive identical characters" do
      user.password = "Password11111!"
      user.password_confirmation = "Password11111!"
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include('cannot contain more than 3 consecutive identical characters.')
    end

    it "accepts password with exactly 3 consecutive identical characters" do
      user.password = "Password111!"
      user.password_confirmation = "Password111!"
      expect(user).to be_valid
    end

    it "accepts password with 2 consecutive identical characters" do
      user.password = "Password11!"
      user.password_confirmation = "Password11!"
      expect(user).to be_valid
    end

    it "accepts password with no consecutive identical characters" do
      user.password = "Password123!"
      user.password_confirmation = "Password123!"
      expect(user).to be_valid
    end
  end

  describe "sequential characters" do
    let(:sequential_passwords) do
      %w[
        Password0123! Password1234! Password2345! Password3456!
        Password4567! Password5678! Password6789! Password7890!
        Passwordabcd! Passwordbcde! Passwordcdef! Passworddefg!
        Passwordefgh! Passwordfghi! Passwordghij! Passwordhijk!
        Passwordijkl! Passwordjklm! Passwordklmn! Passwordlmno!
        Passwordmnop! Passwordnopq! Passwordopqr! Passwordpqrs!
        Passwordqrst! Passwordrstu! Passwordstuv! Passwordtuvw!
        Passworduvwx! Passwordvwxy! Passwordwxyz!
      ]
    end

    it "rejects passwords with sequential numbers" do
      sequential_passwords.select { |p| p.match?(/\d{4}/) }.each do |password|
        user.password = password
        user.password_confirmation = password
        expect(user).not_to be_valid, "Expected #{password} to be invalid"
        expect(user.errors[:password]).to include('cannot contain sequential characters.')
      end
    end

    it "rejects passwords with sequential letters" do
      sequential_passwords.select { |p| p.match?(/[a-z]{4}/) }.each do |password|
        user.password = password
        user.password_confirmation = password
        expect(user).not_to be_valid, "Expected #{password} to be invalid"
        expect(user.errors[:password]).to include('cannot contain sequential characters.')
      end
    end

    it "accepts passwords without sequential characters" do
      user.password = "Password135!"
      user.password_confirmation = "Password135!"
      expect(user).to be_valid
    end

    it "accepts passwords with mixed non-sequential characters" do
      user.password = "Password246!"
      user.password_confirmation = "Password246!"
      expect(user).to be_valid
    end
  end

  describe "password validation conditions" do
    it "validates password when creating new user" do
      user = User.new(name: "Test", email: "test@example.com", password: "password")
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include('is too common. Please choose a more secure password.')
    end

    it "validates password when updating existing user with new password" do
      existing_user = create(:user, password: "OldP@ssw0rd123!", password_confirmation: "OldP@ssw0rd123!")
      existing_user.password = "password"
      existing_user.password_confirmation = "password"
      expect(existing_user).not_to be_valid
      expect(existing_user.errors[:password]).to include('is too common. Please choose a more secure password.')
    end

    it "does not validate password when updating existing user without password change" do
      existing_user = create(:user, password: "OldP@ssw0rd123!", password_confirmation: "OldP@ssw0rd123!")
      existing_user.name = "New Name"
      expect(existing_user).to be_valid
    end

    it "validates password when password is present during update" do
      existing_user = create(:user, password: "OldP@ssw0rd123!", password_confirmation: "OldP@ssw0rd123!")
      existing_user.password = "NewStr0ngP@ssw0rd!"
      existing_user.password_confirmation = "NewStr0ngP@ssw0rd!"
      expect(existing_user).to be_valid
    end
  end

  describe "edge cases" do
    it "handles empty password gracefully" do
      user.password = ""
      user.password_confirmation = ""
      expect(user).not_to be_valid
      # Should have Devise's presence validation error, not our custom validation
      expect(user.errors[:password]).to include("can't be blank")
    end

    it "handles nil password gracefully" do
      user.password = nil
      user.password_confirmation = nil
      expect(user).not_to be_valid
      # Should have Devise's presence validation error, not our custom validation
      expect(user.errors[:password]).to include("can't be blank")
    end

    it "handles very long passwords" do
      long_password = "Aa1!Aa2!Aa3!Aa4!Aa5!Aa6!Aa7!Aa8!Aa9!Aa0!Bb1!Bb2!Bb3!Bb4!Bb5!Bb6!Bb7!Bb8!Bb9!Bb0!"
      user.password = long_password
      user.password_confirmation = long_password
      expect(user).to be_valid
    end

    it "handles passwords with unicode characters" do
      user.password = "P@ssw0rd123!ñ"
      user.password_confirmation = "P@ssw0rd123!ñ"
      expect(user).to be_valid
    end

    it "handles passwords with spaces" do
      user.password = "P@ss w0rd 123!"
      user.password_confirmation = "P@ss w0rd 123!"
      expect(user).to be_valid
    end
  end

  describe "password validation performance" do
    it "validates password quickly for common cases" do
      start_time = Time.current

      user.password = "StrongP@ssw0rd123!"
      user.password_confirmation = "StrongP@ssw0rd123!"
      user.valid?

      end_time = Time.current
      expect(end_time - start_time).to be < 0.1 # Should complete in less than 100ms
    end
  end
end
