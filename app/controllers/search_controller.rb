class SearchController < ApplicationController
  def index
    per_page = 10
    per_page = params[:per_page].to_i if params[:per_page]
    page = 1
    page = params[:page].to_i if params[:page]

    @hosts = Subdomain.all(
        query: { match_all: {} },
        _source: ['host', 'title', 'lastupdatetime'],
        sort:[
            {
                lastupdatetime: "desc"
            }
        ],
        size: per_page,
        from: (page-1)*10)
    @count = Subdomain.es_length
  end

  def result
  end
end
