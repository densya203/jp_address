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
      res = nil
      https = Net::HTTP.new('www.post.japanpost.jp',443)
      https.use_ssl = true
      https.start {
        res = https.get('/zipcode/dl/kogaki/zip/ken_all.zip')
      }
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
      _merge_same_zip_addresses
      _remove_csv
    end

    # 同じ郵便番号を持つレコードを統合します。
    #
    # 例：9896712
    #   "宮城県","大崎市","鳴子温泉水沼"
    #   "宮城県","大崎市","鳴子温泉南山"
    #   "宮城県","大崎市","鳴子温泉山際"
    #   "宮城県","大崎市","鳴子温泉和田"
    # これらは
    #   "宮城県","大崎市","鳴子温泉" として１つのレコードにします。
    #   共通する地名が抜き出せない場合は空の町名にします。
    def self._merge_same_zip_addresses
      group(:zip).having('count(*) > 1').pluck(:zip).each do |dup_zip|
        buf = nil
        town_names = []
        where(zip: dup_zip).order(:id).each_with_index do |rec, i|
          town_names << rec.town if rec.town.present?
          if i == 0
            buf = rec.dup
          end
          rec.destroy
        end
        shared_town_name = _find_shared_name_from(town_names)
        buf.town = shared_town_name
        buf.save!
      end
      nil
    end

    # 引数に渡された地名群から、先頭から見て共通となる地名を返します。
    #
    # input = %w[鳴子温泉小身川
    #            鳴子温泉川袋
    #            鳴子温泉木戸脇
    #         ]
    #
    # return => 鳴子温泉
    def self._find_shared_name_from(names)
      return '' if names.blank?

      name_length_min = names.map{ |n| n.length }.min
      diff_pos        = nil
      chars           = []

      (0..(name_length_min - 1)).each do |pos|
        break if diff_pos.present?
        char = nil
        names.each do |name|
          if char.nil?
            char  = name.each_char.to_a[pos]
            chars << char
          elsif char != name.each_char.to_a[pos]
            diff_pos = pos
            break
          end
        end
      end

      if diff_pos.present? && diff_pos > 1
        ret = chars[0, diff_pos].join
        return ret
      end

      ''
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
