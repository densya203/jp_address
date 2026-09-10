require 'rails_helper'

module JpAddress
  RSpec.describe Zipcode, type: :model do
    let(:sample_csv)    { 'spec/support/files/sample_ken.csv' }
    let(:multiline_csv) { 'spec/support/files/sample_ken_multiline.csv' }

    after do
      FileUtils.rm_f Zipcode::MASTER_CSV_PATH
    end

    describe ".download_master_file_from_japanpost" do
      it "downloads the archive from japan-post and extracts the csv" do
        stub_request(:get, Zipcode::MASTER_FILE_URL)
          .to_return(status: 200, body: build_zip_binary(sample_csv), headers: { 'Content-Type' => 'application/zip' })

        expect(Zipcode.download_master_file_from_japanpost).to eq :success
        expect(File.exist?(Zipcode::MASTER_CSV_PATH)).to be true
      end

      it "follows redirects" do
        redirect_to = 'https://www.post.japanpost.jp/zipcode/dl/kogaki/zip/moved.zip'
        stub_request(:get, Zipcode::MASTER_FILE_URL)
          .to_return(status: 302, headers: { 'Location' => redirect_to })
        stub_request(:get, redirect_to)
          .to_return(status: 200, body: build_zip_binary(sample_csv))

        expect(Zipcode.download_master_file_from_japanpost).to eq :success
      end

      it "raises when japan-post answers with an error" do
        stub_request(:get, Zipcode::MASTER_FILE_URL).to_return(status: 503)

        expect { Zipcode.download_master_file_from_japanpost }.to raise_error(Zipcode::DownloadError, /503/)
      end

      it "raises when the archive holds no csv" do
        zip = Zip::OutputStream.write_buffer do |zos|
          zos.put_next_entry('README.txt')
          zos.write 'not a csv'
        end.string
        stub_request(:get, Zipcode::MASTER_FILE_URL).to_return(status: 200, body: zip)

        expect { Zipcode.download_master_file_from_japanpost }.to raise_error(Zipcode::DownloadError, /no CSV/)
      end
    end

    describe ".load_master_data" do
      it "load master data csv to table" do
        Zipcode.load_master_data sample_csv
        expect(Zipcode.count).to eq 5
        expect(Zipcode.last.prefecture).to eq '北海道'
      end

      it "clears the table before loading" do
        create(:jp_address_zipcode, zip: '9999999')
        Zipcode.load_master_data sample_csv
        expect(Zipcode.find_by(zip: '9999999')).to be_nil
      end

      it "merges the rows that share a zipcode into a single record" do
        Zipcode.load_master_data multiline_csv

        expect(Zipcode.count).to eq 4
        expect(Zipcode.find_by(zip: '9896712').town).to eq '鳴子温泉'
      end

      it "keeps the town name when every row of a zipcode carries the same one" do
        Zipcode.load_master_data multiline_csv

        expect(Zipcode.find_by(zip: '1006690').town).to eq '大手町'
      end

      # 町域名が長い場合、ken_all.csv は括弧の途中で改行して次の行に続く。
      # その続きの行を町域名として扱ってしまうと町名が消えてしまう。
      it "ignores the continuation rows of a town name split over several lines" do
        Zipcode.load_master_data multiline_csv

        record = Zipcode.find_by(zip: '9292225')
        expect(record.town).to eq '米出'
        expect(record.city).to eq '羽咋郡宝達志水町'
      end

      it "leaves the town empty for 以下に掲載がない場合" do
        Zipcode.load_master_data multiline_csv

        expect(Zipcode.find_by(zip: '0600000').town).to eq ''
      end

      it "downloads the master file when the csv is not there yet" do
        stub_request(:get, Zipcode::MASTER_FILE_URL)
          .to_return(status: 200, body: build_zip_binary(sample_csv))

        Zipcode.load_master_data
        expect(Zipcode.count).to eq 5
      end

      it "removes the downloaded csv when it is done" do
        stub_request(:get, Zipcode::MASTER_FILE_URL)
          .to_return(status: 200, body: build_zip_binary(sample_csv))

        Zipcode.load_master_data
        expect(File.exist?(Zipcode::MASTER_CSV_PATH)).to be false
      end
    end

    describe "._remove_needless_words" do
      it "remove needless words" do
        expect(Zipcode.send(:_remove_needless_words, '以下に掲載がない場合')).to eq ''
        expect(Zipcode.send(:_remove_needless_words, '大通西（１～１９丁目）')).to eq '大通西'
      end

      it "tolerates a missing town column" do
        expect(Zipcode.send(:_remove_needless_words, nil)).to eq ''
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
        expect(Zipcode._find_shared_name_from(list)).to eq '鳴子温泉'

        list = %w[
          大通東
          大通西
          大通西
        ]
        expect(Zipcode._find_shared_name_from(list)).to eq '大通'

        list = %w[
          大通西
          大通東
          旭ケ丘
        ]
        expect(Zipcode._find_shared_name_from(list)).to eq ''

        list = %w[
          大分
          大阪
        ]
        expect(Zipcode._find_shared_name_from(list)).to eq ''
      end

      it "returns the name itself when there is only one" do
        expect(Zipcode._find_shared_name_from(%w[東中島])).to eq '東中島'
      end

      it "returns the name itself when every name is the same" do
        expect(Zipcode._find_shared_name_from(%w[大手町 大手町])).to eq '大手町'
      end

      it "returns the shortest name when it is a prefix of the others" do
        expect(Zipcode._find_shared_name_from(%w[東中島 東中島本町])).to eq '東中島'
      end

      it "returns an empty string for an empty list" do
        expect(Zipcode._find_shared_name_from([])).to eq ''
        expect(Zipcode._find_shared_name_from(nil)).to eq ''
      end

      it "ignores blank names" do
        expect(Zipcode._find_shared_name_from(['', nil, '大手町'])).to eq '大手町'
      end
    end
  end
end
