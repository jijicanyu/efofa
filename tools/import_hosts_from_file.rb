#!/usr/bin/env ruby

if ARGV.size<1
  puts "Usage : <FILE>"
  exit
end

@root_path = File.expand_path(File.dirname(__FILE__))
#puts @root_path
require @root_path+"/../config/initializers/sidekiq.rb"
require @root_path+"/../app/workers/checkurl.rb"

File.open(ARGV[0]).each_line{|line|
  host = line.strip
  print "#{host}                                        \r"
  CheckUrlWorker.perform_async(host)
}


