namespace :fofa do

  current_path = File.expand_path('../', __FILE__)


  desc "Start db link crawler"
  task :start_dblinkcrawler  => :environment do
    syscmd ="cd #{current_path} ; nohup ./tools/db_link_crawler.rb &"
    puts "Running syscmd: #{syscmd}"
    system(syscmd)
  end

  desc "Add host"
  task :addhost, [:host] do |t, args|
    tools_path = File.expand_path(File.join(current_path, '..', '..', 'tools'))
    puts tools_path
    puts args
    syscmd ="cd #{tools_path} ; ./addhost.rb #{args[:host]}"
    puts "Running syscmd: #{syscmd}"
    system(syscmd)
  end

end
