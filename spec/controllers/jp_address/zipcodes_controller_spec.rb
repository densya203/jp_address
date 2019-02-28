require 'rails_helper'

module JpAddress
  RSpec.describe ZipcodesController, type: :controller do
    routes { JpAddress::Engine.routes }

    describe "GET #search" do
      it "returns http success" do
        get :search
        expect(response).to have_http_status(:success)
      end
      it "returns valid data when a vaild zip is passed" do
        FactoryBot.create(:jp_address_zipcode)
        get :search, params: {zip: '5330033'}
        expect(response.body).to match '"zip":"5330033","prefecture":"大阪府","city":"大阪市東淀川区","town":"東中島"'
      end
      it "returns empty data when a invaild zip is passed" do
        FactoryBot.create(:jp_address_zipcode)
        get :search, params: {zip: '9999999'}
        expect(response.body).to match '"id":null,"zip":null,"prefecture":null,"city":null,"town":null'
      end
    end

  end
end
