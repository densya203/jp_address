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

    describe "._find_shared_name_from" do
      it "find shared name" do
        list = %w[
          鳴子温泉小身川
          鳴子温泉川袋
          鳴子温泉木戸脇
          鳴子温泉黒崎
          鳴子温泉小室
          鳴子温泉小室山
          鳴子温泉境松
        ]
        expect(JpAddress::Zipcode.send(:_find_shared_name_from, list)).to eq '鳴子温泉'

        list = %w[
          大通東
          大通西
          大通西
        ]
        expect(JpAddress::Zipcode.send(:_find_shared_name_from, list)).to eq '大通'

        list = %w[
          大通西
          大通東
          旭ケ丘
        ]
        expect(JpAddress::Zipcode.send(:_find_shared_name_from, list)).to eq ''

        list = %w[
          大分
          大阪
        ]
        expect(JpAddress::Zipcode.send(:_find_shared_name_from, list)).to eq ''
      end
    end
  end
end
