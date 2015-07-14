#!/usr/bin/env ruby
#提交host工具，默认超过90天才更新，不过可以设置第二个参数来强制刷新
if __FILE__==$0
  if ARGV.size<1
    puts "Usage : #{ARGV[0]} <URL> [force_update, default=0]"
  end

  @root_path = File.expand_path(File.dirname(__FILE__))
  #puts @root_path
  require @root_path+"/../config/initializers/sidekiq.rb"
  require @root_path+"/../app/workers/checkurl.rb"
  CheckUrlWorker.perform_async('webscan.360.cn')
end
