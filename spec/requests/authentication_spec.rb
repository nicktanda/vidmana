require 'rails_helper'

RSpec.describe "Authentication", type: :request do
  describe "GET /users/sign_in" do
    it "renders the login page" do
      get new_user_session_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Log in")
      expect(response.body).to include("Email")
      expect(response.body).to include("Password")
    end
  end

  describe "GET /users/sign_up" do
    it "renders the registration page" do
      get new_user_registration_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Sign up")
      expect(response.body).to include("Name")
      expect(response.body).to include("Email")
      expect(response.body).to include("Password")
    end
  end

  describe "POST /users" do
    context "with valid parameters" do
      let(:valid_attributes) do
        {
          name: "John Doe",
          email: "john@example.com",
          password: "StrongP@ssw0rd123!",
          password_confirmation: "StrongP@ssw0rd123!"
        }
      end

      it "creates a new user" do
        expect {
          post user_registration_path, params: { user: valid_attributes }
        }.to change(User, :count).by(1)
      end

      it "redirects to the home page after registration" do
        post user_registration_path, params: { user: valid_attributes }
        expect(response).to redirect_to(root_path)
      end

      it "signs in the user after registration" do
        post user_registration_path, params: { user: valid_attributes }
        user = User.last
        expect(controller.current_user).to eq(user)
      end
    end

    context "with invalid parameters" do
      it "does not create a user with missing name" do
        invalid_attributes = {
          email: "john@example.com",
          password: "StrongP@ssw0rd123!",
          password_confirmation: "StrongP@ssw0rd123!"
        }

        expect {
          post user_registration_path, params: { user: invalid_attributes }
        }.not_to change(User, :count)
      end

      it "does not create a user with invalid email" do
        invalid_attributes = {
          name: "John Doe",
          email: "invalid-email",
          password: "StrongP@ssw0rd123!",
          password_confirmation: "StrongP@ssw0rd123!"
        }

        expect {
          post user_registration_path, params: { user: invalid_attributes }
        }.not_to change(User, :count)
      end

      it "does not create a user with short password" do
        invalid_attributes = {
          name: "John Doe",
          email: "john@example.com",
          password: "123",
          password_confirmation: "123"
        }

        expect {
          post user_registration_path, params: { user: invalid_attributes }
        }.not_to change(User, :count)
      end
    end
  end

  describe "POST /users/sign_in" do
    let(:user) { create(:user, email: "john@example.com", password: "StrongP@ssw0rd123!") }

    context "with valid credentials" do
      it "signs in the user successfully" do
        post user_session_path, params: {
          user: { email: user.email, password: "StrongP@ssw0rd123!" }
        }
        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("Hello #{user.name}!")
      end

      it "redirects to the home page after sign in" do
        post user_session_path, params: {
          user: { email: user.email, password: "StrongP@ssw0rd123!" }
        }
        expect(response).to redirect_to(root_path)
      end
    end

    context "with invalid credentials" do
      it "does not sign in the user with wrong password" do
        post user_session_path, params: {
          user: { email: "john@example.com", password: "wrongpassword" }
        }
        expect(controller.current_user).to be_nil
      end

      it "does not sign in the user with wrong email" do
        post user_session_path, params: {
          user: { email: "wrong@example.com", password: "StrongP@ssw0rd123!" }
        }
        expect(controller.current_user).to be_nil
      end

      it "renders the sign in page with errors" do
        post user_session_path, params: {
          user: { email: "john@example.com", password: "wrongpassword" }
        }
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Invalid Email or password")
      end
    end
  end

  describe "DELETE /users/sign_out" do
    let(:user) { create(:user) }

    it "signs out the user" do
      sign_in user
      delete destroy_user_session_path
      expect(controller.current_user).to be_nil
    end

    it "redirects to the home page after sign out" do
      sign_in user
      delete destroy_user_session_path
      expect(response).to redirect_to(root_path)
    end
  end
end
