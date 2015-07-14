class SearchController < ApplicationController
  def index
    @count = Subdomain.es_length
  end

  def result
  end
end
