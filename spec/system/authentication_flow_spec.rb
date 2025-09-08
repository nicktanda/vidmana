require 'rails_helper'

RSpec.describe "Authentication Flow", type: :system do
  before do
    driven_by(:rack_test)
  end

  describe "User registration" do
    it "allows a user to register with valid information" do
      visit root_path

      expect(page).to have_content("Welcome to Vidmana")
      expect(page).to have_link("Sign Up")

      click_link "Sign Up"

      expect(page).to have_content("Sign up")
      expect(page).to have_field("Name")
      expect(page).to have_field("Email")
      expect(page).to have_field("Password")
      expect(page).to have_field("Password confirmation")

      fill_in "Name", with: "John Doe"
      fill_in "Email", with: "john@example.com"
      fill_in "Password", with: "StrongP@ssw0rd123!"
      fill_in "Password confirmation", with: "StrongP@ssw0rd123!"

      click_button "Sign up"

      expect(page).to have_content("Welcome to Vidmana")
      expect(page).to have_content("Hello John Doe!")
      expect(page).to have_content("john@example.com")
      expect(page).to have_button("Logout")
      expect(page).not_to have_link("Sign In")
      expect(page).not_to have_link("Sign Up")
    end

    it "shows errors for invalid registration" do
      visit new_user_registration_path

      fill_in "Email", with: "invalid-email"
      fill_in "Password", with: "123"
      fill_in "Password confirmation", with: "456"

      click_button "Sign up"

      expect(page).to have_content("Email is invalid")
      expect(page).to have_content("Password is too short")
      expect(page).to have_content("Password confirmation doesn't match")
      expect(page).to have_content("Name can't be blank")
    end
  end

  describe "User sign in" do
    let!(:user) { create(:user, name: "Jane Smith", email: "jane@example.com", password: "StrongP@ssw0rd123!") }

    it "allows a registered user to sign in" do
      visit root_path

      expect(page).to have_link("Sign In")

      click_link "Sign In"

      expect(page).to have_content("Log in")
      expect(page).to have_field("Email")
      expect(page).to have_field("Password")

      fill_in "Email", with: "jane@example.com"
      fill_in "Password", with: "StrongP@ssw0rd123!"

      click_button "Log in"

      expect(page).to have_content("Welcome to Vidmana")
      expect(page).to have_content("Hello Jane Smith!")
      expect(page).to have_content("jane@example.com")
      expect(page).to have_button("Logout")
    end

    it "shows error for invalid credentials" do
      visit new_user_session_path

      fill_in "Email", with: "jane@example.com"
      fill_in "Password", with: "wrongpassword"

      click_button "Log in"

      expect(page).to have_content("Invalid Email or password")
      expect(page).to have_content("Log in")
    end
  end

  describe "User sign out" do
    let!(:user) { create(:user, name: "Bob Wilson", email: "bob@example.com") }

    it "allows a signed-in user to sign out" do
      visit root_path

      # Sign in first
      click_link "Sign In"
      fill_in "Email", with: "bob@example.com"
      fill_in "Password", with: "StrongP@ssw0rd123!"
      click_button "Log in"

      expect(page).to have_content("Hello Bob Wilson!")
      expect(page).to have_button("Logout")

      click_button "Logout"

      expect(page).to have_content("Welcome to Vidmana")
      expect(page).to have_content("Please sign in or sign up to get started")
      expect(page).to have_link("Sign In")
      expect(page).to have_link("Sign Up")
      expect(page).not_to have_content("Hello Bob Wilson!")
    end
  end

  describe "Navigation links" do
    context "when not signed in" do
      it "shows public navigation links" do
        visit root_path

        expect(page).to have_link("Home")
        expect(page).to have_link("Sign In")
        expect(page).to have_link("Sign Up")
        expect(page).not_to have_link("Edit Profile")
        expect(page).not_to have_button("Logout")
      end
    end

    context "when signed in" do
      let!(:user) { create(:user, name: "Alice Johnson") }

      it "shows authenticated navigation links" do
        visit root_path
        click_link "Sign In"
        fill_in "Email", with: user.email
        fill_in "Password", with: "StrongP@ssw0rd123!"
        click_button "Log in"

        expect(page).to have_content("Welcome, Alice Johnson!")
        expect(page).to have_link("Home")
        expect(page).to have_link("Edit Profile")
        expect(page).to have_button("Logout")
        expect(page).not_to have_link("Sign In")
        expect(page).not_to have_link("Sign Up")
      end
    end
  end

  describe "Protected content" do
    let!(:user) { create(:user, name: "Charlie Brown") }
    let!(:story) { create(:story, user: user, title: "My Great Story", description: "An amazing tale") }

    it "shows user's stories when signed in" do
      visit root_path
      click_link "Sign In"
      fill_in "Email", with: user.email
      fill_in "Password", with: "StrongP@ssw0rd123!"
      click_button "Log in"

      expect(page).to have_content("Your Stories")
      expect(page).to have_content("My Great Story")
      expect(page).to have_content("An amazing tale")
    end

    it "shows empty state when user has no stories" do
      new_user = create(:user, name: "David Smith")

      visit root_path
      click_link "Sign In"
      fill_in "Email", with: new_user.email
      fill_in "Password", with: "StrongP@ssw0rd123!"
      click_button "Log in"

      expect(page).to have_content("Your Stories")
      expect(page).to have_content("You haven't created any stories yet")
    end
  end
end
