namespace :fofa do

  current_path = File.expand_path('../', __FILE__)

  desc "Show running workers"
  task :show_workers do
    ps = `ps -eo pid,command | grep sidekiq | grep -v grep`
    puts ps
  end

  desc "Restart running workers"
  task :restart_workers => :environment do
    Rake::Task['fofa:stop_workers'].invoke
    Rake::Task['fofa:start_workers'].invoke
  end

  desc "Quit running workers"
  task :stop_workers => :environment do
    syscmd = "ps aux | grep sidekiq | grep -v grep  | awk '{print $2}' | xargs -n 1 kill -s QUIT"
    puts "Running syscmd: #{syscmd}"
    system(syscmd)
    #end
  end

  desc "Quit running workers force"
  task :stop_workers_force => :environment do
    syscmd = "ps aux | grep sidekiq | grep -v grep  | awk '{print $2}' | xargs -n 1 kill -9"
    puts "Running syscmd: #{syscmd}"
    system(syscmd)
    #end
  end

  desc "Start workers (threads can set by WCNT environment)"
  task :start_workers => :environment do
    `rm -f #{Rails.root}/log/*.log`
    puts "Starting #{ENV['WCNT']} worker(s)"
    concurrency = ''
    concurrency = '-c '+ENV['WCNT'] if ENV['WCNT']
    ops = {:pgroup => true, :err => [(Rails.root + "log/workers_error.log").to_s, "a"],
           :out => [(Rails.root + "log/workers.log").to_s, "a"]}
    env_vars = {"RAILS_ENV"=>"production"}
    cmd = "bundle exec sidekiq -L #{Rails.root}/log/workers.log -C #{Rails.root}/config/sidekiq.yml #{concurrency} -d"
    puts cmd
    pid = spawn(env_vars, cmd, ops)
    Process.detach(pid)
  end


  desc 'Runs Sidekiq as a rake task'
  task :debug_sidekiq => :environment do
    require 'sidekiq'
    require 'sidekiq/cli'
    begin
      cli = Sidekiq::CLI.instance
      cli.parse
      cli.run
    rescue => e
      raise e if $DEBUG
      STDERR.puts e.message
      STDERR.puts e.backtrace.join("\n")
      exit 1
    end
  end

end