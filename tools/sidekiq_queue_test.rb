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

fetch = Sidekiq::BasicFetch.new(:queues => ['update_index'])
while 1
  work = fetch.retrieve_work
  if work
    msg = Sidekiq.load_json(work.message)
    args = msg['args']
    puts "update index task: #{args[0]}, #{msg['class']}"
    update_index(*args)
  else
    print '.'
    sleep 1
  end
end