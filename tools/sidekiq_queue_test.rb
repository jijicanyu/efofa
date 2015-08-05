#!/usr/bin/env ruby
require 'yaml'
@root_path = File.expand_path(File.dirname(__FILE__))
require @root_path+"/../config/initializers/sidekiq.rb"
require 'elasticsearch'
require 'elasticsearch/model'
require @root_path+"/../config/initializers/elasticsearch.rb"
require 'celluloid'
require 'sidekiq/fetch'
require @root_path+"/../app/workers/updateindex.rb"
require @root_path+"/../app/workers/checkurl.rb"
include Lrlink
require 'thread/pool'

pool = Thread.pool(30)
$bulks = []

def bulk_submit
  puts "bulk update index task: #{$bulks.map{|h| h['host'] }}"
  Subdomain.es_bulk_insert($bulks)
  $bulks.clear
end

fetch = Sidekiq::BasicFetch.new(:queues => ['update_index', 'check_url'])
while 1
  work = fetch.retrieve_work
  if work
    msg = Sidekiq.load_json(work.message)
    pool.process(msg){|msg|
      args = msg['args']
      if msg['class'] == 'UpdateIndexWorker'
        update_index(*args){|http_info|
          $bulks << http_info
          false
        }
        bulk_submit if $bulks.size>=10
      elsif msg['class'] == 'CheckUrlWorker'
        print '.'
        #puts "check url task: #{args[0]}"
        checkurl(*args)
      end
    }
  else
    bulk_submit if $bulks.size>0 #获取不到新任务就把队列的先提交
    print '.'
    sleep 1
  end
end