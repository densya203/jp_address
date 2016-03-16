require 'rails_helper'

module JpAddress
  RSpec.describe Zipcode, type: :model do

    describe ".download_master_file_from_japanpost" do
      it "download zipcode file from japan-postal-site" do
        VCR.use_cassette 'download_master_file_from_japanpost' do
          expect(JpAddress::Zipcode.download_master_file_from_japanpost).to eq :success
        end
      end
    end

    describe ".load_master_data" do
      it "load master data csv to table" do
        JpAddress::Zipcode.load_master_data 'spec/support/files/sample_ken.csv'
        expect(JpAddress::Zipcode.count).to eq 5
        expect(JpAddress::Zipcode.last.prefecture).to eq '北海道'
      end
    end

    describe "._remove_needless_words" do
      it "remove needless words" do
        expect(JpAddress::Zipcode.send(:_remove_needless_words, '以下に掲載がない場合')).to eq ''
        expect(JpAddress::Zipcode.send(:_remove_needless_words, '大通西（１～１９丁目）')).to eq '大通西'
      end
    end
  end
end
