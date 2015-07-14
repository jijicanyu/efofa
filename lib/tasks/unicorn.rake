namespace :fofa do

  current_path = File.expand_path('../', __FILE__)

  desc "Zero-downtime restart of Unicorn"
  task :restart_unicorn  => :environment do
    syscmd = "cd #{current_path} ; kill -s USR2 `cat tmp/unicorn.pid`"
    puts "Running syscmd: #{syscmd}"
    system(syscmd)

    Rake::Task["fofa:precompile"]
  end

  desc "Start unicorn"
  task :start_unicorn  => :environment do
    syscmd = "cd #{current_path} ; unicorn_rails -E production --listen 3000 -D -c config/unicorn.rb"
    puts "Running syscmd: #{syscmd}"
    system(syscmd)

    Rake::Task["fofa:precompile"]
  end

  desc "Precompile assets"
  task :precompile => :environment do
    ENV['RAKE_ENV'] = 'production'
    Rake::Task["assets:precompile"] #assets:precompile RAILS_ENV=production
  end

  desc "Stop unicorn"
  task :stop_unicorn  => :environment do
    syscmd ="cd #{current_path} ; kill -s QUIT `cat tmp/unicorn.pid`; rm -f tmp/unicorn.pid"
    puts "Running syscmd: #{syscmd}"
    system(syscmd)
  end

end
