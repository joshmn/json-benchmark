require 'securerandom'
require 'optparse'

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

  opts.on('-a', '--all', "All the kinds") do |v|
    options[:all] = true
  end
end.parse!

options[:limit] ||= 100000

# Sorry
if options[:all]
  file = File.read("app/controllers/homes_controller.rb").each_line.detect { |line| line.index("@types = ") }
  eval(file)
end

def self.run(options)
  puts "On #{options.inspect}"
  random = SecureRandom.hex
  query = "homes.json?via=#{options[:kind]}&limit=#{options[:limit]}&bob=#{random}"
  filename = "results/result-#{options[:kind]}-#{options[:limit]}.txt"
  system("ab -n 5 'http://localhost:3000/#{query}' > #{filename}")

  #log = `cat log/development.log | grep -A 6 '/#{query}'`.strip
  log = `sed -n '/#{query}/,/Completed 200/p' log/development.log`
  response_builder = File.read('app/controllers/homes_controller.rb').split("when '#{options[:kind]}'", 2)[1].split("when")[0].split(" end")[0].strip
  open(filename, 'a') { |f| f.puts "\nRails response builder\n#{response_builder}\n\n\nRails request log\n#{log}" }
end

puts "Warming up"
5.times do
  `curl -s http://localhost:3000`
end

puts "Running"
if(defined?(@types))
  @types.each { |type| options[:kind] = type; run(options) }
else
  run(options)
end
