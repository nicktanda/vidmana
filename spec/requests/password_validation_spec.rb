require 'rails_helper'

RSpec.describe "Password Validation", type: :request do
  describe "User Registration with Password Validation" do
    let(:valid_user_params) do
      {
        user: {
          name: "John Doe",
          email: "john@example.com",
          password: "StrongP@ssw0rd123!",
          password_confirmation: "StrongP@ssw0rd123!"
        }
      }
    end

    context "with valid strong password" do
      it "creates a new user successfully" do
        expect {
          post user_registration_path, params: valid_user_params
        }.to change(User, :count).by(1)

        expect(response).to have_http_status(:redirect)
        expect(response).to redirect_to(root_path)
      end
    end

    context "with weak passwords" do
      let(:weak_passwords) do
        %w[
          password password123 123456 123456789 qwerty abc123
          password1 admin 12345678 1234567 12345 1234 123
          letmein welcome monkey 1234567890 dragon master
          hello freedom whatever qazwsx trustno1
        ]
      end

      it "rejects registration with common weak passwords" do
        weak_passwords.each do |weak_password|
          params = valid_user_params.deep_dup
          params[:user][:password] = weak_password
          params[:user][:password_confirmation] = weak_password

          expect {
            post user_registration_path, params: params
          }.not_to change(User, :count)

          expect(response).to have_http_status(:unprocessable_content)
          expect(response.body).to include("is too common. Please choose a more secure password.")
        end
      end
    end

    context "with passwords lacking required character types" do
      it "rejects password without uppercase letter" do
        params = valid_user_params.deep_dup
        params[:user][:password] = "password123!"
        params[:user][:password_confirmation] = "password123!"

        expect {
          post user_registration_path, params: params
        }.not_to change(User, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("must be at least 8 characters long and contain at least one uppercase letter, one lowercase letter, one number, and one special character.")
      end

      it "rejects password without lowercase letter" do
        params = valid_user_params.deep_dup
        params[:user][:password] = "PASSWORD123!"
        params[:user][:password_confirmation] = "PASSWORD123!"

        expect {
          post user_registration_path, params: params
        }.not_to change(User, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("must be at least 8 characters long and contain at least one uppercase letter, one lowercase letter, one number, and one special character.")
      end

      it "rejects password without number" do
        params = valid_user_params.deep_dup
        params[:user][:password] = "Password!"
        params[:user][:password_confirmation] = "Password!"

        expect {
          post user_registration_path, params: params
        }.not_to change(User, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("must be at least 8 characters long and contain at least one uppercase letter, one lowercase letter, one number, and one special character.")
      end

      it "rejects password without special character" do
        params = valid_user_params.deep_dup
        params[:user][:password] = "MyPassword123"
        params[:user][:password_confirmation] = "MyPassword123"

        expect {
          post user_registration_path, params: params
        }.not_to change(User, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("must be at least 8 characters long and contain at least one uppercase letter, one lowercase letter, one number, and one special character.")
      end

      it "rejects password shorter than 8 characters" do
        params = valid_user_params.deep_dup
        params[:user][:password] = "Pass1!"
        params[:user][:password_confirmation] = "Pass1!"

        expect {
          post user_registration_path, params: params
        }.not_to change(User, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("must be at least 8 characters long and contain at least one uppercase letter, one lowercase letter, one number, and one special character.")
      end
    end

    context "with passwords containing repeated characters" do
      it "rejects password with more than 3 consecutive identical characters" do
        params = valid_user_params.deep_dup
        params[:user][:password] = "Password1111!"
        params[:user][:password_confirmation] = "Password1111!"

        expect {
          post user_registration_path, params: params
        }.not_to change(User, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("cannot contain more than 3 consecutive identical characters.")
      end

      it "accepts password with exactly 3 consecutive identical characters" do
        params = valid_user_params.deep_dup
        params[:user][:password] = "Password111!"
        params[:user][:password_confirmation] = "Password111!"

        expect {
          post user_registration_path, params: params
        }.to change(User, :count).by(1)

        expect(response).to have_http_status(:redirect)
      end
    end

    context "with passwords containing sequential characters" do
      it "rejects password with sequential numbers" do
        params = valid_user_params.deep_dup
        params[:user][:password] = "Password1234!"
        params[:user][:password_confirmation] = "Password1234!"

        expect {
          post user_registration_path, params: params
        }.not_to change(User, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("cannot contain sequential characters.")
      end

      it "rejects password with sequential letters" do
        params = valid_user_params.deep_dup
        params[:user][:password] = "Passwordabcd!"
        params[:user][:password_confirmation] = "Passwordabcd!"

        expect {
          post user_registration_path, params: params
        }.not_to change(User, :count)

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("cannot contain sequential characters.")
      end

      it "accepts password without sequential characters" do
        params = valid_user_params.deep_dup
        params[:user][:password] = "Password135!"
        params[:user][:password_confirmation] = "Password135!"

        expect {
          post user_registration_path, params: params
        }.to change(User, :count).by(1)

        expect(response).to have_http_status(:redirect)
      end
    end
  end

  describe "Password Change with Validation" do
    let(:user) { create(:user, password: "OldP@ssw0rd123!", password_confirmation: "OldP@ssw0rd123!") }

    before do
      sign_in user
    end

    context "with valid strong password" do
      it "allows password change with strong password" do
        patch user_registration_path, params: {
          user: {
            current_password: "OldP@ssw0rd123!",
            password: "NewStr0ngP@ssw0rd!",
            password_confirmation: "NewStr0ngP@ssw0rd!"
          }
        }

        expect(response).to have_http_status(:redirect)
        expect(user.reload.valid_password?("NewStr0ngP@ssw0rd!")).to be true
      end
    end

    context "with weak passwords" do
      it "rejects password change with weak password" do
        patch user_registration_path, params: {
          user: {
            current_password: "OldP@ssw0rd123!",
            password: "password",
            password_confirmation: "password"
          }
        }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("is too common. Please choose a more secure password.")
        expect(user.reload.valid_password?("password")).to be false
      end
    end

    context "when not changing password" do
      it "allows profile update without password change" do
        patch user_registration_path, params: {
          user: {
            current_password: "OldP@ssw0rd123!",
            name: "Updated Name"
          }
        }

        expect(response).to have_http_status(:redirect)
        expect(user.reload.name).to eq("Updated Name")
      end
    end
  end
end
