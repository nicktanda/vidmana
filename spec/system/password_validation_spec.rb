require 'rails_helper'

RSpec.describe "Password Validation in UI", type: :system do
  include Devise::Test::IntegrationHelpers
  describe "User Registration Form" do
    before do
      visit new_user_registration_path
    end

    it "displays password requirements" do
      expect(page).to have_content("Password must contain:")
      expect(page).to have_content("At least 8 characters")
      expect(page).to have_content("One uppercase letter")
      expect(page).to have_content("One lowercase letter")
      expect(page).to have_content("One number")
      expect(page).to have_content("One special character")
      expect(page).to have_content("No common passwords")
      expect(page).to have_content("No sequential characters")
      expect(page).to have_content("No more than 3 consecutive identical characters")
    end

    context "with weak password" do
      it "shows error for common weak password" do
        fill_in "Name", with: "John Doe"
        fill_in "Email", with: "john@example.com"
        fill_in "Password", with: "password"
        fill_in "Password confirmation", with: "password"

        click_button "Sign up"

        expect(page).to have_content("is too common. Please choose a more secure password.")
        expect(page).to have_current_path(new_user_registration_path)
      end

      it "shows error for password without special character" do
        fill_in "Name", with: "John Doe"
        fill_in "Email", with: "john@example.com"
        fill_in "Password", with: "MyPassword123"
        fill_in "Password confirmation", with: "MyPassword123"

        click_button "Sign up"

        expect(page).to have_content("must be at least 8 characters long and contain at least one uppercase letter, one lowercase letter, one number, and one special character.")
        expect(page).to have_current_path(new_user_registration_path)
      end

      it "shows error for password with sequential characters" do
        fill_in "Name", with: "John Doe"
        fill_in "Email", with: "john@example.com"
        fill_in "Password", with: "Password1234!"
        fill_in "Password confirmation", with: "Password1234!"

        click_button "Sign up"

        expect(page).to have_content("cannot contain sequential characters.")
        expect(page).to have_current_path(new_user_registration_path)
      end

      it "shows error for password with too many consecutive identical characters" do
        fill_in "Name", with: "John Doe"
        fill_in "Email", with: "john@example.com"
        fill_in "Password", with: "Password1111!"
        fill_in "Password confirmation", with: "Password1111!"

        click_button "Sign up"

        expect(page).to have_content("cannot contain more than 3 consecutive identical characters.")
        expect(page).to have_current_path(new_user_registration_path)
      end
    end

    context "with strong password" do
      it "successfully creates user with strong password" do
        fill_in "Name", with: "John Doe"
        fill_in "Email", with: "john@example.com"
        fill_in "Password", with: "StrongP@ssw0rd123!"
        fill_in "Password confirmation", with: "StrongP@ssw0rd123!"

        click_button "Sign up"

        expect(page).to have_content("Welcome to Vidmana")
        expect(page).to have_content("Hello John Doe!")
        expect(page).to have_current_path(root_path)
      end
    end
  end

  describe "Password Edit Form" do
    let(:user) { create(:user, password: "OldP@ssw0rd123!", password_confirmation: "OldP@ssw0rd123!") }

    before do
      sign_in user
      visit edit_user_registration_path
    end

    it "displays password requirements" do
      expect(page).to have_content("Password must contain:")
      expect(page).to have_content("At least 8 characters")
      expect(page).to have_content("One uppercase letter")
      expect(page).to have_content("One lowercase letter")
      expect(page).to have_content("One number")
      expect(page).to have_content("One special character")
      expect(page).to have_content("No common passwords")
      expect(page).to have_content("No sequential characters")
      expect(page).to have_content("No more than 3 consecutive identical characters")
    end

    context "with weak password" do
      it "shows error for common weak password" do
        fill_in "Current password", with: "OldP@ssw0rd123!"
        fill_in "Password", with: "password"
        fill_in "Password confirmation", with: "password"

        click_button "Update"

        expect(page).to have_content("is too common. Please choose a more secure password.")
        expect(page).to have_current_path(edit_user_registration_path)
      end

      it "shows error for password without special character" do
        fill_in "Current password", with: "OldP@ssw0rd123!"
        fill_in "Password", with: "MyPassword123"
        fill_in "Password confirmation", with: "MyPassword123"

        click_button "Update"

        expect(page).to have_content("must be at least 8 characters long and contain at least one uppercase letter, one lowercase letter, one number, and one special character.")
        expect(page).to have_current_path(edit_user_registration_path)
      end
    end

    context "with strong password" do
      it "successfully updates password with strong password" do
        fill_in "Current password", with: "OldP@ssw0rd123!"
        fill_in "Password", with: "NewStr0ngP@ssw0rd!"
        fill_in "Password confirmation", with: "NewStr0ngP@ssw0rd!"

        click_button "Update"

        expect(page).to have_content("Your account has been updated successfully.")
        expect(page).to have_current_path(root_path)
      end
    end

    context "without changing password" do
      it "allows profile update without password change" do
        fill_in "Current password", with: "OldP@ssw0rd123!"
        fill_in "Email", with: "updated@example.com"

        click_button "Update"

        expect(page).to have_content("Your account has been updated successfully.")
        expect(page).to have_current_path(root_path)
        expect(user.reload.email).to eq("updated@example.com")
      end
    end
  end

  describe "Password Requirements Styling" do
    before do
      visit new_user_registration_path
    end

    it "applies proper styling to password requirements" do
      password_requirements = page.find('.password-requirements')

      expect(password_requirements).to be_visible
      expect(password_requirements).to have_css('small')
      expect(password_requirements).to have_css('strong')
    end
  end
end
