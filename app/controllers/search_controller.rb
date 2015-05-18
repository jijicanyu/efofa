class SearchController < ApplicationController
  def index
    @count = Subdomain.length
  end

  def result
  end
end
