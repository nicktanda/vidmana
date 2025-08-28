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
    let(:user) { create(:user, password: 'password123') }

    it 'encrypts the password' do
      expect(user.encrypted_password).not_to eq('password123')
      expect(user.encrypted_password).to be_present
    end

    it 'authenticates with correct password' do
      expect(user.valid_password?('password123')).to be true
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