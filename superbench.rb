require 'securerandom'
require 'optparse'
require_relative 'config/environment'
require 'csv'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: superbench.rb [options]"

  opts.on("-n", "--number [NUMBER]", Integer, "Number of requests") do |v|
    options[:number] = v || 5
  end

  opts.on('-k', '--kind [KIND]', "Kind of request") do |v|
    options[:kind] = v
  end

  opts.on('-l', '--limit [LIMIT]', "Limit") do |v|
    options[:limit] = v
  end

  opts.on('-h', '--host [HOST]', "Host") do |v|
    options[:host] = "young-spire-59440.herokuapp.com"
  end

  opts.on('-a', '--all', "All the kinds") do |v|
    options[:all] = true
  end
end.parse!

options[:limit] ||= 100000

# Sorry
if options[:all]
  @types = SerializeManager.types
end

options[:host] ||= '127.0.0.1:3000'
puts options.inspect
def self.run(options)
  puts "On #{options.inspect}"
  random = SecureRandom.hex
  query = "homes.json?via=#{options[:kind]}&limit=#{options[:limit]}&bob=#{random}"
  filename = "results/result-#{options[:kind]}-#{options[:limit]}-#{options[:host]}.txt"
  system("ab -n #{options[:number]} -s 120 'http://#{options[:host]}/#{query}' > #{filename}")
  if options[:host].index("heroku")
    `heroku logs -n 1000 > #{random}-log.txt`
    log = `sed -n '/#{query}/,/Completed 200/p' #{random}-log.txt`
    `rm #{random}-log.txt`
  else
    log = `sed -n '/#{query}/,/Completed 200/p' log/#{ENV['RAILS_ENV'] || 'development'}.log`
  end
  response_builder = SerializeManager.description(options[:kind])
  open(filename, 'a') { |f| f.puts "\nDescription\n#{response_builder}\n\n\nRails request log\n#{log}" }
  results = {runs: [], averages: {}}
  log.lines.select { |line| line.index("Completed 200 OK") }.each do |line|
    total = line.split(" in ", 2)[1].split("(", 2)[0].strip
    views = line.split("Views: ", 2)[1].split(" |")[0]
    activerecord = line.split("ActiveRecord: ", 2)[1].split(" |")[0]
    allocations = line.split("Allocations: ", 2)[1].split(" )")[0]
    results[:runs] << { total: total.to_i, views: views.to_f.to_d, db: activerecord.to_f.to_d, allocations: allocations.to_i}
  end

  log.lines.select { |line| line.index("MEMSTAT") }.each_with_index do |line, index|
    mems = line.split("MEMSTAT: ", 2)[1]
    retained, allocated = mems.split(' / ').map(&:to_i)
    results[:runs][index][:retained] = retained
    results[:runs][index][:allocated] = allocated
  end

  log.lines.select { |line| line.index("RESPONSE BODY SIZE") }.each_with_index do |line, index|
    response_body = line.split("RESPONSE BODY SIZE: ", 2)[1].to_i
    results[:runs][index][:response_body] = response_body
  end

  results[:runs][0].keys.each do |key|
    results[:averages][key] = (results[:runs].map { |result| result[key] }.inject(&:+).to_d / results[:runs].size.to_d).to_s
  end
  results[:builder] = response_builder
  results
end

puts "Warming up"
5.times do
  `curl -s http://localhost:3000`
end

results_table = {}

puts "Running"
if(defined?(@types))
  @types.each { |type| options[:kind] = type; results_table[type] = run(options) }
else
  results_table[options[:kind]] = run(options)
end

pp results_table

headers = false
file = CSV.generate do |csv|
  results_table.each do |k,v|
    unless headers
      csv << ["Name", *v[:averages].keys, "Builder"]
      headers = true
    end
    csv << [k, v[:averages].values.map { |value| value.to_f.round(2) }, v[:builder]].flatten
  end
end

File.write("results.csv", file)
