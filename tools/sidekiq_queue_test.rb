#!/usr/bin/env
require 'yaml'
@root_path = File.expand_path(File.dirname(__FILE__))
require "sidekiq"
require @root_path+"/../config/initializers/sidekiq.rb"
require 'celluloid'
require 'sidekiq/fetch'
require @root_path+"/../app/workers/updateindex.rb"
require @root_path+"/../app/workers/checkurl.rb"
include Lrlink

fetch = Sidekiq::BasicFetch.new(:queues => ['update_index'])
w = UpdateIndexWorker.new
while 1
  work = fetch.retrieve_work
  if work
    args = Sidekiq.load_json(work.message)['args']
    puts "update index task: #{args[0]}"
    w.perform(*args)
  else
    print '.'
    sleep 1
  end
end