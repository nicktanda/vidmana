require 'rails_helper'

RSpec.describe "ManaPrompts", type: :request do
  describe "GET /index" do
    it "returns http success" do
      get "/mana_prompts/index"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /edit" do
    it "returns http success" do
      get "/mana_prompts/edit"
      expect(response).to have_http_status(:success)
    end
  end

end
