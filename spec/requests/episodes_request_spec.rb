require 'rails_helper'

RSpec.describe "Episodes", type: :request do

  describe "GET /index" do
    it "returns http success" do
      get "/"
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /show" do
    it "returns http success" do
      get "/episodes/show"
      expect(response).to have_http_status(:success)
    end
  end


  describe "GET index" do
    it "has a 200 status code" do
      get root_path
      expect(response.status).to eq(200)
    end
  end
end
