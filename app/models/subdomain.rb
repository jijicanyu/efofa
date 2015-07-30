require 'elasticsearch'
require 'elasticsearch/persistence/model'

=begin
model继承的几个方法：

count是获取查询语句对应Elasticsearch::Persistence::Model::Find的count，也就是说是取查询返回数据的个数
  构造的查询语句是: http://127.0.0.1:9200/fofa/subdomain/_search?search_type=count ；
  es_count对应的查询语句是: http://127.0.0.1:9200/fofa/subdomain/_count

search:
  返回的是Elasticsearch::Persistence::Repository::Response::Results: http://www.rubydoc.info/gems/elasticsearch-persistence/Elasticsearch/Persistence/Repository/Response/Results
    totol 返回的总数，results是返回结果数组
  es_search对应的是返回原始数据，json格式：result['hits']['total']
=end
class Subdomain
  include Elasticsearch::Persistence::Model

  index_name 'fofa'
  document_type 'subdomain'
  @client = Elasticsearch::Persistence.client
  @index = index_name
  @type = document_type

  attribute :id,  Integer
  attribute :host,  String
  attribute :title,  String
  attribute :ip,  String
  attribute :body,  String
  attribute :domain,  String
  attribute :subdomain,  String
  attribute :reverse_domain,  String
  attribute :header,  String
  attribute :lastchecktime, Time
  attribute :lastupdatetime, Time

  class << self
    def index
      @index
    end

    def index=(index)
      index_name index
      @index = index_name
    end

    def es_size
      @client.count(index: @index, type: @type)['count']
    end

    alias :es_length :es_size


    #文档个数
    def es_count(index=nil)
      index ||= @index
      @client.count(index: index, type: @type)['count']
    rescue
      0
    end

=begin
    #查找，系统自带的更好用
    def es_search(query)
      @client.search index: @index, type: @type, q: query
    rescue
      nil
    end
=end

    #是否存在某条文档
    def es_exists?(host)
      @client.exists index: @index, type: @type, id: host
    end

    #按id查找document
    def es_get(host,fields=nil)
      query = {index: @index, type: @type, id: host}
      query[:fields] = fields if fields
      @client.get query
    rescue
      nil
    end

    def es_delete(host)
      @client.delete index: @index, type: @type, id: host
    end

    def es_bulk_insert(articles)
      @client.bulk({
                                                index: ::Article.__elasticsearch__.index_name,
                                                type: ::Article.__elasticsearch__.document_type,
                                                body: prepare_records(articles)
                                            })
    end

    #插入文档

    def es_insert(host, domain, subdomain, r)
      title = r['title']
      title ||= ''
      header = r['header']
      body = r['utf8html']
      body ||= ''
      ip = r['ip']

      @client.index index: @index, type: @type,
                    id: host,
                    body: {
                        host: host,
                        domain: domain,
                        reverse_domain: domain.reverse,
                        subdomain: subdomain,
                        ip: ip,
                        header: header,
                        title: title,
                        body: body.force_encoding('UTF-8'),
                        lastchecktime: r['lastchecktime'] || Time.now().to_s,
                        lastupdatetime: r['lastupdatetime'] || Time.now().to_s,
                    }, refresh: true
    end

    def update_checktime_of_host(host)
      @client.update index: @index, type: @type,
                     id: host,
                     body: {
                         doc: {
                             lastchecktime: Time.now().to_s
                         }
                     }, refresh: true
    end
  end


end