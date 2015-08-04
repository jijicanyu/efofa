class SearchController < ApplicationController
  def index
    @per_page = 10
    @per_page = params[:per_page].to_i if params[:per_page]
    @page = 1
    @page = params[:page].to_i if params[:page]
    @hosts = Subdomain.search(query: { term: {domain: '360.cn'} },
        _source: ['host', 'title', 'lastupdatetime', 'ip'],
        sort:[
            {
                lastupdatetime: "desc"
            }
        ]).paginate(page: @page, per_page: @per_page)
    @count = Subdomain.es_length
  end

  def result
  end
end
