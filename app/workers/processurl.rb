require "lrlink.rb"
require "httpmodule.rb"

class ProcessUrlWorker
  include Lrlink
  include Sidekiq::Worker
  include HttpModule

  ERROR_BLACK_IP = -6

  sidekiq_options :queue => :process_url, :retry => 3, :backtrace => true#, :unique => true, :unique_job_expiration => 120 * 60 # 2 hours

  sidekiq_retries_exhausted do |msg|
    Sidekiq.logger.warn "Failed #{msg['class']} with #{msg['args']}: #{msg['error_message']}"
  end

  def initialize
  end

  def perform(host, domain, subdomain, addlinkhosts=true, userid=0)
    process_url(host, domain, subdomain, addlinkhosts, userid)
  end

  def process_url(host, domain, subdomain, addlinkhosts=true, userid=0)
    #获取http信息
    http_info = get_http(host)
    if http_info && ! http_info[:error]
      return ERROR_BLACK_IP if is_bullshit_ip?(http_info[:ip])

      #提交下一个队列
      Sidekiq::Client.enqueue(UpdateIndexWorker, host, domain, subdomain, http_info, addlinkhosts, userid)

      return 0
    elsif http_info
      Sidekiq::Client.enqueue(HttpErrorWorker, host, domain, subdomain, http_info)
      return -7
    end
  end
end