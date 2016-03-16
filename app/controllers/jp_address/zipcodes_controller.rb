require_dependency "jp_address/application_controller"

module JpAddress
  class ZipcodesController < ApplicationController
    def search
      @zipcode = Zipcode.find_by(:zip => params[:zip]) || Zipcode.new
      render text: @zipcode.to_json
    end
  end
end
