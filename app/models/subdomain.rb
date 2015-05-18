require 'elasticsearch/persistence/model'

class Subdomain
  include Elasticsearch::Persistence::Model

  index_name 'fofa'
  document_type 'subdomain'

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

    def size
      Elasticsearch::Persistence.client.count(index: index_name, type: document_type)['count']
    end

    alias :length :size
  end
end