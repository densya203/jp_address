require_dependency "jp_address/application_controller"

module JpAddress
  class ZipcodesController < ApplicationController
    def search
      @zipcode = Zipcode.find_by(:zip => params[:zip].to_s.gsub(/[^0-9]/, '')) || Zipcode.new
      render plain: @zipcode.to_json
    end
  end
end
