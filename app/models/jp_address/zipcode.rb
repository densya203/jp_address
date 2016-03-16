module JpAddress
  class Zipcode < ActiveRecord::Base

    MASTER_CSV_PATH = 'tmp/ken_all.csv'

    def self.download_master_file_from_japanpost
      _setup_directory
      zip = _save_zip(_request_to_japanpost.body)
      _save_csv(zip.path)
      :success if File.exist?(MASTER_CSV_PATH)
    end

    def self._setup_directory
      FileUtils.mkdir_p 'tmp'
      _remove_csv
    end
    private_class_method :_setup_directory

    def self._request_to_japanpost
      url = URI.parse('http://www.post.japanpost.jp/zipcode/dl/kogaki/zip/ken_all.zip')
      res = Net::HTTP.start(url.host, url.port) do |http|
        http.get('/zipcode/dl/kogaki/zip/ken_all.zip')
      end
      res
    end
    private_class_method :_request_to_japanpost

    def self._save_zip(binary)
      tmp_zip = Tempfile.open('ken_all.zip') do |f|
        f.binmode
        f.write binary
        f
      end
      tmp_zip
    end
    private_class_method :_save_zip

    def self._save_csv(zip_path)
      Zip::File.open(zip_path) do |zip_file|
        zip_file.each do |entry|
          entry.extract(MASTER_CSV_PATH)
        end
      end
    end
    private_class_method :_save_csv

    def self.load_master_data(csv_path = MASTER_CSV_PATH)
      download_master_file_from_japanpost if !File.exist?(csv_path)
      _clear_table
      CSV.foreach(csv_path, encoding:'SJIS:UTF-8') do |row|
        connection.execute(
          sanitize_sql(
            ["insert into jp_address_zipcodes (zip, prefecture, city, town)
              values ('%s', '%s', '%s', '%s')", row[2], row[6], row[7], _remove_needless_words(row[8])
            ]
          )
        )
      end
      _remove_csv
    end

    def self._clear_table
      begin
        connection.truncate 'jp_address_zipcodes'
      rescue NotImplementedError
        connection.execute 'delete from jp_address_zipcodes'
      end
    end
    private_class_method :_clear_table

    def self._remove_needless_words(base)
      base.sub(/以下に掲載がない場合/, '').sub(/（.*/, '')
    end
    private_class_method :_remove_needless_words

    def self._remove_csv
      FileUtils.rm_rf MASTER_CSV_PATH
    end
    private_class_method :_remove_csv

  end
end
