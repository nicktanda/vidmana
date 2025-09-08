require 'rails_helper'

RSpec.describe "Home", type: :request do
  describe "GET /" do
    context "when user is not signed in" do
      it "returns http success" do
        get root_path
        expect(response).to have_http_status(:success)
      end

      it "displays public content" do
        get root_path
        expect(response.body).to include("Welcome to Vidmana")
        expect(response.body).to include("sign in")
        expect(response.body).to include("sign up")
      end

      it "shows sign in and sign up links" do
        get root_path
        expect(response.body).to include("Sign In")
        expect(response.body).to include("Sign Up")
      end
    end

    context "when user is signed in" do
      let(:user) { create(:user, name: "Test User") }

      before do
        sign_in user
      end

      it "returns http success" do
        get root_path
        expect(response).to have_http_status(:success)
      end

      it "displays personalized content" do
        get root_path
        expect(response.body).to include("Hello Test User!")
        expect(response.body).to include(user.email)
      end

      it "shows user stories section" do
        get root_path
        expect(response.body).to include("Your Stories")
      end

      context "with stories" do
        let!(:story) { create(:story, user: user, title: "My Story", description: "Great story") }

        it "displays user's stories" do
          get root_path
          expect(response.body).to include("My Story")
          expect(response.body).to include("Great story")
        end
      end

      context "without stories" do
        it "displays empty state" do
          get root_path
          expect(response.body).to include("You haven't created any stories yet")
        end
      end
    end
  end
end
