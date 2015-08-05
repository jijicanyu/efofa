#!/usr/bin/env ruby
@root_path = File.expand_path(File.dirname(__FILE__))
$: << @root_path+"/../app/workers/"
#puts @root_path
require @root_path+"/../config/initializers/sidekiq.rb"
require @root_path+"/../app/workers/processurl.rb"
require @root_path+"/../app/workers/updateindex.rb"
include HttpModule

http_info = get_http('0-www.cairn.info.sso.scd.univ-tours.fr')
if http_info && ! http_info[:error]
  if http_info[:utf8html].force_encoding('UTF-8').valid_encoding?
    puts 'ok'
  end
  if http_info[:title].force_encoding('UTF-8').valid_encoding?
    puts 'ok'
  end
  if http_info[:header].force_encoding('UTF-8').valid_encoding?
    puts 'ok'
  end
  mini_info={ip:http_info[:ip], title:http_info[:title], header:http_info[:header], utf8html:http_info[:utf8html]}
  puts Sidekiq::Client.enqueue(UpdateIndexWorker, "0-www.cairn.info.sso.scd.univ-tours.fr", "univ-tours.fr", "0-www.cairn.info.sso.scd", mini_info, true, 0)
end

