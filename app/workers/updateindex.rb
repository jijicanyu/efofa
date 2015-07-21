require File.join(FOFA_ROOT_PATH, 'workers', 'lrlink.rb')
require File.join(FOFA_ROOT_PATH, 'workers', 'fofadb.rb')
require File.join(FOFA_ROOT_PATH, 'models', 'subdomain.rb')

class UpdateIndexWorker
  include Sidekiq::Worker

  sidekiq_options :queue => :update_index, :retry => 3, :backtrace => true#, :unique => true, :unique_job_expiration => 120 * 60 # 2 hours

  sidekiq_retries_exhausted do |msg|
    Sidekiq.logger.warn "Failed #{msg['class']} with #{msg['args']}: #{msg['error_message']}"
  end

  def initialize
  end

  def perform(host, domain, subdomain, http_info, addlinkhosts, userid=0)
    update_index(host, domain, subdomain, http_info, addlinkhosts, userid)
  end

  def update_index(host, domain, subdomain, http_info, addlinkhosts, userid=0)
    #puts http_info
    FofaDB.changecount(host,domain,http_info['ip']) unless Subdomain.exists?(host) #更新计数，用于加黑
    Subdomain.es_insert(host,domain,subdomain,http_info) #更新索引


    FofaDB.add_user_points(userid, 'host', 1) if userid>0

    utf8html = http_info['utf8html']

    if addlinkhosts
      hosts = get_linkes(utf8html).select {|h|
        !FofaDB.redis_black_host?(h) && !Subdomain.exists?(h) && !FofaDB.redis_black_ip?(get_ip_of_host(host_of_url(h)))
      }

      if hosts.size>0
        hosts.each {|h|
          Sidekiq::Client.enqueue(CheckUrlWorker, h)
        }
      end
    end
  end
end