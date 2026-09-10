require 'rails_helper'

RSpec.describe 'JpAddress::Zipcodes', type: :request do
  # dummy アプリは engine を /jp_address にマウントしている。
  let(:search_path) { '/jp_address/zipcodes/search' }

  describe "GET #search" do
    it "returns http success" do
      get search_path
      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq 'application/json'
    end

    it "returns valid data when a vaild zip is passed" do
      create(:jp_address_zipcode)
      get search_path, params: { zip: '5330033' }
      expect(response.parsed_body).to include(
        'zip'        => '5330033',
        'prefecture' => '大阪府',
        'city'       => '大阪市東淀川区',
        'town'       => '東中島'
      )
    end

    it "returns empty data when a invaild zip is passed" do
      create(:jp_address_zipcode)
      get search_path, params: { zip: '9999999' }
      expect(response.parsed_body).to include(
        'id' => nil, 'zip' => nil, 'prefecture' => nil, 'city' => nil, 'town' => nil
      )
    end

    it "returns empty data when no zip is passed" do
      create(:jp_address_zipcode)
      get search_path
      expect(response.parsed_body['id']).to be_nil
    end

    it "ignores hyphens and spaces in the zip" do
      create(:jp_address_zipcode)
      get search_path, params: { zip: ' 533-0033 ' }
      expect(response.parsed_body['zip']).to eq '5330033'
    end

    it "accepts a zip typed with full-width digits" do
      create(:jp_address_zipcode)
      get search_path, params: { zip: '５３３－００３３' }
      expect(response.parsed_body['zip']).to eq '5330033'
    end
  end
end
