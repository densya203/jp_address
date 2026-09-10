module JpAddress
  class Zipcode < ApplicationRecord

    # 日本郵便からダウンロードした CSV の一時保存先。
    MASTER_CSV_PATH = 'tmp/ken_all.csv'.freeze

    # 郵便番号データ（住所の郵便番号／小書き）の配布 URL。
    MASTER_FILE_URL = 'https://www.post.japanpost.jp/zipcode/dl/kogaki/zip/ken_all.zip'.freeze

    # insert_all で一度に流し込む件数。
    INSERT_BATCH_SIZE = 1_000

    # リダイレクトを追う上限。
    MAX_REDIRECTS = 5

    class DownloadError < StandardError; end

    def self.download_master_file_from_japanpost
      _setup_directory
      tmp_zip = _save_zip(_request_to_japanpost)
      begin
        _save_csv(tmp_zip.path)
      ensure
        tmp_zip.close!
      end
      :success if File.exist?(MASTER_CSV_PATH)
    end

    def self._setup_directory
      FileUtils.mkdir_p File.dirname(MASTER_CSV_PATH)
      _remove_csv
    end
    private_class_method :_setup_directory

    def self._request_to_japanpost(url = MASTER_FILE_URL, redirect_limit = MAX_REDIRECTS)
      raise DownloadError, "too many redirects while downloading #{MASTER_FILE_URL}" if redirect_limit <= 0

      uri = URI.parse(url)
      res = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |https|
        https.get(uri.request_uri)
      end

      case res
      when Net::HTTPSuccess
        res.body
      when Net::HTTPRedirection
        location = res['location']
        raise DownloadError, "got a redirect without a location from #{url}" if location.nil?

        _request_to_japanpost(URI.join(url, location).to_s, redirect_limit - 1)
      else
        raise DownloadError, "failed to download #{url} (#{res.code} #{res.message})"
      end
    end
    private_class_method :_request_to_japanpost

    def self._save_zip(binary)
      tmp_zip = Tempfile.new(['ken_all', '.zip'])
      tmp_zip.binmode
      tmp_zip.write binary
      tmp_zip.flush
      tmp_zip.close
      tmp_zip
    end
    private_class_method :_save_zip

    def self._save_csv(zip_path)
      Zip::File.open(zip_path) do |zip_file|
        entry = zip_file.find { |e| e.file? && File.extname(e.name).downcase == '.csv' }
        raise DownloadError, "no CSV file found in the archive from #{MASTER_FILE_URL}" if entry.nil?

        entry.extract(MASTER_CSV_PATH)
      end
    end
    private_class_method :_save_csv

    # CSV を読み込んでテーブルを作り直します。
    #
    # 同じ郵便番号を持つ行は１レコードに統合してから insert するので、
    # 郵便番号はテーブル内で一意になります。
    def self.load_master_data(csv_path = MASTER_CSV_PATH)
      unless File.exist?(csv_path)
        raise ArgumentError, "#{csv_path} does not exist" unless csv_path == MASTER_CSV_PATH

        download_master_file_from_japanpost
      end

      _clear_table
      transaction do
        _each_record_batch_from(csv_path) { |batch| insert_all!(batch) }
      end
      _remove_csv
      nil
    end

    # CSV を郵便番号ごとにまとめ、insert_all に渡せる Hash の配列を
    # INSERT_BATCH_SIZE 件ずつ yield します。
    def self._each_record_batch_from(csv_path)
      _read_master_csv(csv_path).each_value.each_slice(INSERT_BATCH_SIZE) do |slice|
        yield slice.map { |rec|
          {
            zip:        rec[:zip],
            prefecture: rec[:prefecture],
            city:       rec[:city],
            town:       _find_shared_name_from(rec[:towns])
          }
        }
      end
    end
    private_class_method :_each_record_batch_from

    # 郵便番号をキーにして CSV の行をまとめます。
    # 都道府県名・市区町村名は同じ郵便番号の最初の行のものを採用します。
    #
    # 例：9896712
    #   "宮城県","大崎市","鳴子温泉水沼"
    #   "宮城県","大崎市","鳴子温泉南山"
    #   "宮城県","大崎市","鳴子温泉山際"
    #   "宮城県","大崎市","鳴子温泉和田"
    # これらは
    #   "宮城県","大崎市","鳴子温泉" として１つのレコードにします。
    #   共通する地名が抜き出せない場合は空の町名にします。
    #
    # ken_all.csv では町域名が長いと括弧の途中で改行され、次の行に続きます。
    #   "米出（１２４、１２５、１２７、"
    #   "１４８、１４９、１５４番地）"
    # 続きの行は町域名ではないので、括弧が閉じるまでの行は読み飛ばします。
    def self._read_master_csv(csv_path)
      records = {}
      # 郵便番号ごとの「閉じていない括弧の数」。0 より大きい間は継続行。
      open_parens = Hash.new(0)

      # ken_all.csv の文字コードは CP932（Ruby では SJIS が CP932 の別名）。
      CSV.foreach(csv_path, encoding: 'CP932:UTF-8') do |row|
        zip = row[2].to_s.strip
        next if zip.empty?

        raw_town = row[8].to_s
        if open_parens[zip] > 0
          open_parens[zip] += _paren_balance(raw_town)
          next
        end
        open_parens[zip] = [_paren_balance(raw_town), 0].max

        record = (records[zip] ||= {
          zip:        zip,
          prefecture: row[6].to_s.strip,
          city:       row[7].to_s.strip,
          towns:      []
        })
        town = _remove_needless_words(raw_town)
        record[:towns] << town if town.present?
      end
      records
    end
    private_class_method :_read_master_csv

    def self._paren_balance(text)
      text.count('（') - text.count('）')
    end
    private_class_method :_paren_balance

    # 引数に渡された地名群から、先頭から見て共通となる地名を返します。
    #
    # input = %w[鳴子温泉小身川
    #            鳴子温泉川袋
    #            鳴子温泉木戸脇
    #         ]
    #
    # return => 鳴子温泉
    #
    # 共通部分が１文字しかない場合（例：大分／大阪）は、地名として意味を
    # なさないので空文字を返します。ただし短い方の地名がまるごと共通部分に
    # なる場合（例：東中島／東中島本町）は、その地名をそのまま返します。
    def self._find_shared_name_from(names)
      names = Array(names).reject { |name| name.blank? }
      return '' if names.empty?

      shortest      = names.min_by { |name| name.length }
      shared_length = 0
      shortest.each_char.with_index do |char, pos|
        break unless names.all? { |name| name[pos] == char }

        shared_length = pos + 1
      end

      return shortest if shared_length == shortest.length

      shared_length > 1 ? shortest[0, shared_length] : ''
    end

    def self._clear_table
      connection_pool.with_connection do |conn|
        begin
          conn.truncate table_name
        rescue NotImplementedError
          conn.delete "delete from #{conn.quote_table_name(table_name)}"
        end
      end
    end
    private_class_method :_clear_table

    def self._remove_needless_words(base)
      base.to_s.sub(/以下に掲載がない場合/, '').sub(/（.*/, '').strip
    end
    private_class_method :_remove_needless_words

    def self._remove_csv
      FileUtils.rm_f MASTER_CSV_PATH
    end
    private_class_method :_remove_csv

  end
end
