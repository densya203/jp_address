module ZipHelper
  # 指定したファイルを１件だけ収めた zip をメモリ上に作って返します。
  def build_zip_binary(source_path, entry_name: 'KEN_ALL.CSV')
    Zip::OutputStream.write_buffer do |zos|
      zos.put_next_entry(entry_name)
      zos.write File.binread(source_path)
    end.string
  end
end

RSpec.configure do |config|
  config.include ZipHelper
end
