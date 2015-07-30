#!/usr/bin/env ruby
require 'yaml'
@root_path = File.expand_path(File.dirname(__FILE__))
require @root_path+"/../config/initializers/sidekiq.rb"
require 'elasticsearch'
require 'elasticsearch/persistence'
require @root_path+"/../config/initializers/elasticsearch.rb"
require 'celluloid'
require 'sidekiq/fetch'
require @root_path+"/../app/workers/updateindex.rb"
require @root_path+"/../app/workers/checkurl.rb"
include Lrlink
require 'thread/pool'

pool = Thread.pool(30)

fetch = Sidekiq::BasicFetch.new(:queues => ['update_index', 'check_url'])
while 1
  work = fetch.retrieve_work
  if work
    msg = Sidekiq.load_json(work.message)
    pool.process(msg){|msg|
      args = msg['args']
      if msg['class'] == 'UpdateIndexWorker'
        puts "update index task: #{args[0]}"
        update_index(*args)
      elsif msg['class'] == 'CheckUrlWorker'
        puts "check url task: #{args[0]}"
        checkurl(*args)
      end
    }
  else
    print '.'
    sleep 1
  end
end