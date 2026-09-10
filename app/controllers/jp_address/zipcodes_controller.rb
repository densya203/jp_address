module JpAddress
  class ZipcodesController < ApplicationController
    def search
      @zipcode = Zipcode.find_by(zip: _normalized_zip) || Zipcode.new
      render json: @zipcode
    end

    private

    # 全角数字・ハイフン・空白などを取り除いて半角数字だけにします。
    def _normalized_zip
      params[:zip].to_s.tr('０-９', '0-9').gsub(/[^0-9]/, '')
    end
  end
end
