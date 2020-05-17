if ENV['TIMES']
  HOMES = ENV['TIMES'].to_i
else
  HOMES = 100_000
end

puts "Currently there are #{Home.count} homes. Making #{HOMES}."

records = []
HOMES.times do |i|
  records << { latitude: rand(-90.0...90.0), longitude: rand(-180.0...180.0), created_at: Time.now, updated_at: Time.now }
end

Home.insert_all(records)
puts "Homes: #{Home.count}"
