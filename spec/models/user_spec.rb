require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { should have_many(:stories).dependent(:destroy) }
  end

  describe 'validations' do
    subject { build(:user) }
    
    it { should validate_presence_of(:name) }
    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should validate_presence_of(:password) }
    it { should validate_length_of(:password).is_at_least(6) }
  end

  describe 'password strength validation' do
    let(:user) { build(:user) }

    context 'when password is weak' do
      let(:weak_passwords) do
        %w[
          password password123 123456 123456789 qwerty abc123
          password1 admin 12345678 1234567 12345 1234 123
          letmein welcome monkey 1234567890 dragon master
          hello freedom whatever qazwsx trustno1
        ]
      end

      it 'rejects common weak passwords' do
        weak_passwords.each do |weak_password|
          user.password = weak_password
          user.password_confirmation = weak_password
          expect(user).not_to be_valid
          expect(user.errors[:password]).to include('is too common. Please choose a more secure password.')
        end
      end
    end

    context 'when password lacks required character types' do
      it 'rejects password without uppercase letter' do
        user.password = 'password123!'
        user.password_confirmation = 'password123!'
        expect(user).not_to be_valid
        expect(user.errors[:password]).to include('must be at least 8 characters long and contain at least one uppercase letter, one lowercase letter, one number, and one special character.')
      end

      it 'rejects password without lowercase letter' do
        user.password = 'PASSWORD123!'
        user.password_confirmation = 'PASSWORD123!'
        expect(user).not_to be_valid
        expect(user.errors[:password]).to include('must be at least 8 characters long and contain at least one uppercase letter, one lowercase letter, one number, and one special character.')
      end

      it 'rejects password without number' do
        user.password = 'Password!'
        user.password_confirmation = 'Password!'
        expect(user).not_to be_valid
        expect(user.errors[:password]).to include('must be at least 8 characters long and contain at least one uppercase letter, one lowercase letter, one number, and one special character.')
      end

      it 'rejects password without special character' do
        user.password = 'Password123'
        user.password_confirmation = 'Password123'
        expect(user).not_to be_valid
        expect(user.errors[:password]).to include('is too common. Please choose a more secure password.')
      end

      it 'rejects password without special character (not in weak list)' do
        user.password = 'MyPassword123'
        user.password_confirmation = 'MyPassword123'
        expect(user).not_to be_valid
        expect(user.errors[:password]).to include('must be at least 8 characters long and contain at least one uppercase letter, one lowercase letter, one number, and one special character.')
      end

      it 'rejects password shorter than 8 characters' do
        user.password = 'Pass1!'
        user.password_confirmation = 'Pass1!'
        expect(user).not_to be_valid
        expect(user.errors[:password]).to include('must be at least 8 characters long and contain at least one uppercase letter, one lowercase letter, one number, and one special character.')
      end
    end

    context 'when password has repeated characters' do
      it 'rejects password with more than 3 consecutive identical characters' do
        user.password = 'Password1111!'
        user.password_confirmation = 'Password1111!'
        expect(user).not_to be_valid
        expect(user.errors[:password]).to include('cannot contain more than 3 consecutive identical characters.')
      end

      it 'accepts password with exactly 3 consecutive identical characters' do
        user.password = 'Password111!'
        user.password_confirmation = 'Password111!'
        expect(user).to be_valid
      end
    end

    context 'when password has sequential characters' do
      it 'rejects password with sequential numbers' do
        user.password = 'Password1234!'
        user.password_confirmation = 'Password1234!'
        expect(user).not_to be_valid
        expect(user.errors[:password]).to include('cannot contain sequential characters.')
      end

      it 'rejects password with sequential letters' do
        user.password = 'Passwordabcd!'
        user.password_confirmation = 'Passwordabcd!'
        expect(user).not_to be_valid
        expect(user.errors[:password]).to include('cannot contain sequential characters.')
      end

      it 'accepts password without sequential characters' do
        user.password = 'Password135!'
        user.password_confirmation = 'Password135!'
        expect(user).to be_valid
      end
    end

    context 'when password meets all requirements' do
      it 'accepts strong password' do
        user.password = 'StrongP@ssw0rd!'
        user.password_confirmation = 'StrongP@ssw0rd!'
        expect(user).to be_valid
      end

      it 'accepts password with mixed case, numbers, and special characters' do
        user.password = 'MyS3cur3P@ss!'
        user.password_confirmation = 'MyS3cur3P@ss!'
        expect(user).to be_valid
      end
    end

    context 'when updating existing user' do
      let(:existing_user) { create(:user, password: 'OldP@ssw0rd!', password_confirmation: 'OldP@ssw0rd!') }

      it 'validates password when password is provided' do
        existing_user.password = 'password'
        existing_user.password_confirmation = 'password'
        expect(existing_user).not_to be_valid
        expect(existing_user.errors[:password]).to include('is too common. Please choose a more secure password.')
      end

      it 'does not validate password when password is not provided' do
        existing_user.name = 'New Name'
        expect(existing_user).to be_valid
      end
    end
  end

  describe 'devise modules' do
    it 'includes database_authenticatable module' do
      expect(User.devise_modules).to include(:database_authenticatable)
    end

    it 'includes registerable module' do
      expect(User.devise_modules).to include(:registerable)
    end

    it 'includes recoverable module' do
      expect(User.devise_modules).to include(:recoverable)
    end

    it 'includes rememberable module' do
      expect(User.devise_modules).to include(:rememberable)
    end

    it 'includes validatable module' do
      expect(User.devise_modules).to include(:validatable)
    end
  end

  describe 'factory' do
    it 'has a valid factory' do
      expect(build(:user)).to be_valid
    end
  end

  describe 'email uniqueness' do
    let!(:existing_user) { create(:user, email: 'test@example.com') }
    
    it 'does not allow duplicate emails' do
      new_user = build(:user, email: 'test@example.com')
      expect(new_user).not_to be_valid
      expect(new_user.errors[:email]).to include('has already been taken')
    end

    it 'is case insensitive for email uniqueness' do
      new_user = build(:user, email: 'TEST@EXAMPLE.COM')
      expect(new_user).not_to be_valid
      expect(new_user.errors[:email]).to include('has already been taken')
    end
  end

  describe 'password encryption' do
    let(:user) { create(:user, password: 'StrongP@ssw0rd123!') }

    it 'encrypts the password' do
      expect(user.encrypted_password).not_to eq('StrongP@ssw0rd123!')
      expect(user.encrypted_password).to be_present
    end

    it 'authenticates with correct password' do
      expect(user.valid_password?('StrongP@ssw0rd123!')).to be true
    end

    it 'does not authenticate with incorrect password' do
      expect(user.valid_password?('wrongpassword')).to be false
    end
  end

  describe 'cascading deletes' do
    let(:user) { create(:user) }
    let!(:story) { create(:story, user: user) }

    it 'destroys associated stories when user is destroyed' do
      expect { user.destroy }.to change(Story, :count).by(-1)
    end
  end
end