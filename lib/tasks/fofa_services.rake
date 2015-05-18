# 所有的启动停止操作都只限于在服务器本地执行
require 'colorize'

def l(info, error=false)
  if error
    puts "[ERROR] #{info}".red
    exit 1
  else
    puts "[INFO] #{info}"
  end
end

def es_found?
  es_home = ENV['ES_HOME']
  if es_home && es_home.size>0
    es_bin = File.join(es_home, "bin/elasticsearch")
    if File.exists?(es_bin)
      l "ES_HOME is set to: #{ENV['ES_HOME']}"
    else
      l "ES_HOME is set to: #{ENV['ES_HOME']}, but file not exists!", true
    end
  else
    l "ES_HOME is not set!", true
  end
  true
end

def es_running?
  begin
    rails_root = ENV['RAILS_ROOT'] || File.dirname(__FILE__) + '/../..'
    rails_env = ENV['RAILS_ENV'] || 'development'
    config = YAML.load_file(rails_root + '/config/database.yml')[rails_env]['elasticsearch']
    elasticsearch_url = "#{config['host']}:#{config['port']}"

    client = Elasticsearch::Client.new url:elasticsearch_url
    return true if client.count
  rescue
    false
  end
end

def redis_running?
  begin
    rails_root = ENV['RAILS_ROOT'] || File.dirname(__FILE__) + '/../..'
    rails_env = ENV['RAILS_ENV'] || 'development'
    config = YAML.load_file(rails_root + '/config/database.yml')[rails_env]['redis']
    l("redis config is not set(/config/database.yml)!", true) unless config && config.size>0
    redis_url = "redis://#{config['host']}:#{config['port']}/#{config['db']}"

    redis = Redis.new(:url=>redis_url)
    return true if redis.ping
  rescue
    false
  end
end

namespace :fofa do
  ########## elasticsearch ##########
  desc '检查elasticsearch运行情况'
  task :es_status => :environment do
    l "checkinging if elasticsearch is running ..."
    if es_running?
      l "elasticsearch is running".green
    else
      l "elasticsearch is not running", true
    end
  end

  desc '启动elasticsearch'
  task :es_start => :environment do
    l "starting elasticsearch..."
    if es_running?
      l "elasticsearch already running..."
    else
      if es_found?
        es_bin = File.join(ENV['ES_HOME'], "bin/elasticsearch")
        pid = Process.spawn("#{es_bin} -d", :out => '/dev/null', :err => '/dev/null')
        Process.detach pid

        while !es_running?
          print '.'
          sleep 1
        end
        puts ""
        l "elasticsearch started."
      end

    end
  end

  desc '停止elasticsearch'
  task :es_stop => :environment do
    l "stopping elasticsearch..."
    unless es_running?
      l "elasticsearch is not running!"
    else
      pid = Process.spawn("ps aux  | grep elasticsearch | grep java | grep -v grep | awk '{print $2}' | xargs kill", :out => '/dev/null', :err => '/dev/null')
      Process.detach pid
      while es_running?
        print '.'
        sleep 1
      end
      puts ""
      l "elasticsearch stopped."
    end
  end

  ########## redis ##########

  desc '检查redis运行情况'
  task :redis_status => :environment do
    l "checkinging if redis is running ..."
    if redis_running?
      l "redis is running".green
    else
      l "redis is not running", true
    end
  end

  desc '启动redis'
  task :redis_start => :environment do
    l "starting redis..."
    if redis_running?
      l "redis already running..."
    else
      # Spawn a new process and run the rake command
      pid = Process.spawn("redis-server", :out => '/dev/null', :err => '/dev/null')

      # Detach the spawned process
      Process.detach pid

      while !redis_running?
        print '.'
        sleep 1
      end
      puts ""
      l "redis started."
    end
  end

  desc '停止redis'
  task :redis_stop => :environment do
    l "stopping redis..."
    unless redis_running?
      l "redis is not running!"
    else
      pid = Process.spawn("ps aux  | grep redis-server | grep -v grep | awk '{print $2}' | xargs kill", :out => '/dev/null', :err => '/dev/null')
      Process.detach pid
      while redis_running?
        print '.'
        sleep 1
      end
      puts ""
      l "redis stopped."
    end
  end

  ########### 所有 ##########
  desc '检查服务运行情况'
  task :status => :environment do
    Rake::Task["fofa:es_status"].invoke
    Rake::Task["fofa:redis_status"].invoke
  end

  desc '运行所有服务'
  task :start_services=> :environment do
    Rake::Task["fofa:es_start"].invoke
    Rake::Task["fofa:redis_start"].invoke
  end

  desc '停止所有服务'
  task :stop_services=> :environment do
    Rake::Task["fofa:es_stop"].invoke
    Rake::Task["fofa:redis_stop"].invoke
  end
end