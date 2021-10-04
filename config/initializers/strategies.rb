class SerializeManager
  class_attribute :registry, default: {}
  def self.register(name, description, &block)
    raise "#{name} already defined" if registry.key?(name.to_s)

    registry[name.to_s] = { description: description, block: block }
  end

  def self.fetch(name)
    raise NotImplementedError, "define #{name} in config/initializers/strategies.rb" unless registry.key?(name)

    registry[name.to_s][:block]
  end

  def self.types
    registry.keys
  end

  def self.description(name)
    raise NotImplementedError, "define #{name} in config/initializers/strategies.rb" unless registry.key?(name)

    registry[name.to_s][:description]
  end
end


SerializeManager.register 'nothing', "Vanilla ActiveModel#to_json using OJ" do |homes|
  render json: homes.as_json, adapter: nil, serializer: nil
end

SerializeManager.register 'nothing_oj', "Vanilla ActiveModel#to_json using OJ" do |homes|
  render json: Oj.dump(homes.as_json, mode: :compat), adapter: nil, serializer: nil
end

SerializeManager.register 'nothing_map', "Maps a collection to a hash" do |homes|
  render json: homes.map { |home| { id: home.id, latitude: home.latitude, longitude: home.longitude } }, adapter: nil, serializer: nil
end

SerializeManager.register 'nothing_map_oj', "Maps a collection to a hash and renders using OJ" do |homes|
  render json: Oj.dump(homes.map { |home| { id: home.id, latitude: home.latitude, longitude: home.longitude }}, mode: :compat), adapter: nil, serializer: nil
end

SerializeManager.register 'asm', "ActiveModelSerializers with ActiveModel" do |homes|
  render json: ActiveModelSerializers::SerializableResource.new(homes, each_serializer: AsmSerializer).to_json
end

SerializeManager.register 'asm_oj', "ActiveModelSerializers with ActiveModel, optimized with OJ" do |homes|
  render json: Oj.dump(ActiveModelSerializers::SerializableResource.new(homes, each_serializer: AsmSerializer).as_json, mode: :compat)
end

SerializeManager.register 'asm_exec_query', "ActiveModelSerializers from a hash via ActiveRecord.exec_query (no ActiveModel)" do |homes|
  homes = Home.connection.exec_query(homes.to_sql)
  render json: ActiveModel::Serializer::CollectionSerializer.new(homes, serializer: AsmArSerializer).to_json
end

SerializeManager.register 'asm_exec_query_oj', "ActiveModelSerializers from a hash via ActiveRecord.exec_query (no ActiveModel), optimized with OJ" do |homes|
  homes = Home.connection.exec_query(homes.to_sql)
  render json: Oj.dump(ActiveModel::Serializer::CollectionSerializer.new(homes, serializer: AsmArSerializer).as_json, mode: :compat)
end

SerializeManager.register 'asm_execute', "ActiveModelSerializers from a hash via ActiveRecord.execute (no ActiveModel), optimized with OJ" do |homes|
  homes = Home.connection.exec_query(homes.to_sql)
  render json: Oj.dump(ActiveModel::Serializer::CollectionSerializer.new(homes, serializer: AsmArSerializer).as_json, mode: :compat)
end

SerializeManager.register 'asm_execute_oj', "ActiveModelSerializers from a hash via ActiveRecord.execute (no ActiveModel), optimized with OJ" do |homes|
  homes = Home.connection.execute(homes.to_sql).to_a
  render json: Oj.dump(ActiveModel::Serializer::CollectionSerializer.new(homes, serializer: AsmArSerializer).as_json, mode: :compat)
end

SerializeManager.register 'fast', "JSON:API Serializer an array of ActiveModel objects" do |homes|
  render json: Fast::HomeSerializer.new(homes).to_json
end

SerializeManager.register 'fast_oj', 'JSON:API Serializer with an array of ActiveModel objects, optimized with OJ' do |homes|
  render json: Oj.dump(Fast::HomeSerializer.new(homes).serializable_hash, mode: :compat)
end

SerializeManager.register 'fast_map', 'JSON:API Serializer, mapped from an array of ActiveModel objects' do |homes|
  render json: homes.map { |home| Fast::HomeSerializer.new(home).serializable_hash }
end

SerializeManager.register 'fast_map_oj', 'JSON:API Serializer, mapped from an array of ActiveModel objects, optimized with OJ' do |homes|
  render json: Oj.dump(homes.map { |home| Fast::HomeSerializer.new(home).serializable_hash }, mode: :compat)
end

SerializeManager.register 'fast_exec_query', 'JSON:API Serializer from a hash via ActiveRecord.exec_query (no ActiveModel)' do |homes|
  homes = Home.connection.exec_query(homes.to_sql)
  render json: homes.to_a { |home| Fast::HomeSerializer.new(home).serializable_hash }
end

SerializeManager.register 'fast_exec_query_oj', 'JSON:API Serializer from a hash via ActiveRecord.exec_query (no ActiveModel), optimized with OJ' do |homes|
  homes = Home.connection.exec_query(homes.to_sql)
  render json: Oj.dump(homes.to_a.map { |home| Fast::HashSerializer.new(home) }, mode: :compat)
end

SerializeManager.register 'fast_execute', 'JSON:API Serializer from a hash via ActiveRecord.execute (no ActiveModel)' do |homes|
  homes = Home.connection.execute(homes.to_sql)
  render json: homes.to_a.map { |home| Fast::HashSerializer.new(home).serializable_hash }.to_json
end

SerializeManager.register 'fast_execute_oj', 'JSON:API Serializer from a hash via ActiveRecord.execute (no ActiveModel), optimized with OJ' do |homes|
  homes = Home.connection.execute(homes.to_sql)
  render json: Oj.dump(homes.map { |home| Fast::HashSerializer.new(home).serializable_hash }, mode: :compat)
end

SerializeManager.register 'jbuilder', 'Jbuilder from an array of ActiveModel objects' do |homes|
  render json: Jbuilder.new { |json| json.array! homes, :id, :latitude, :longitude }.target!, adapter: nil, serializer: nil
end

SerializeManager.register 'jbuilder_map_oj', 'Jbuilder from an array of ActiveModel objects, optimized with OJ' do |homes|
  render json: Oj.dump(Jbuilder.new { |json| json.array! homes, :id, :latitude, :longitude }.target!, mode: :compat), adapter: nil, serializer: nil
end

SerializeManager.register 'execute', 'Hash#to_json via ActiveRecord.execute (no ActiveModel)' do |homes|
  render json: Home.connection.execute(homes.to_sql).to_a.to_json, adapter: nil
end

SerializeManager.register 'execute_oj', 'Hash#to_json via ActiveRecord.execute (no ActiveModel), optimized with OJ' do |homes|
  render json: Oj.dump(Home.connection.execute(homes.to_sql).to_a), adapter: nil
end

SerializeManager.register 'execute_map', 'Array of hashes mapped from ActiveRecord.execute (no ActiveModel)' do |homes|
  render json: Home.connection.execute(homes.to_sql).to_a.map { |home| {id: home['id'], latitude: home['latitude'], longitude: home['longitude'] } }.to_json, adapter: nil
end

SerializeManager.register 'execute_map_oj', 'Array of hashes mapped from ActiveRecord.execute (no ActiveModel), optimized with OJ' do |homes|
  render json: Oj.dump(Home.connection.execute(homes.to_sql).to_a.map { |home| {id: home['id'], latitude: home['latitude'], longitude: home['longitude'] } }, mode: :compat), adapter: nil
end

SerializeManager.register 'exec_query', 'Hash#to_json from ActiveRecord.exec_query (no ActiveModel)' do |homes|
  render json: Home.connection.exec_query(homes.to_sql).to_a.to_json, adapter: nil
end

SerializeManager.register 'exec_query_oj', 'Hash#to_json from ActiveRecord.exec_query (no ActiveModel), optimized with OJ' do |homes|
  render json: Oj.dump(Home.connection.exec_query(homes.to_sql).to_a), adapter: nil
end

SerializeManager.register 'exec_query_map', 'Array of hashes mapped from ActiveRecord.exec_query (no ActiveModel)' do |homes|
  render json: Home.connection.exec_query(homes.to_sql).to_a.map { |home| {id: home['id'], latitude: home['latitude'], longitude: home['longitude'] } }.to_json, adapter: nil
end

SerializeManager.register 'exec_query_map_oj', 'Array of hashes mapped from ActiveRecord.exec_query (no ActiveModel), optimized with OJ' do |homes|
  render json: Oj.dump(Home.connection.exec_query(homes.to_sql).to_a.map { |home| {id: home['id'], latitude: home['latitude'], longitude: home['longitude'] } }, mode: :compat), adapter: nil
end

SerializeManager.register 'pg', 'PostgreSQL json_agg and json_build_object' do |homes|
  query = "select json_agg(json_build_object('id', id, 'latitude', CAST(latitude AS TEXT), 'longitude', CAST(longitude AS TEXT))) from (#{homes.to_sql}) home;"
  render json: Home.connection.exec_query(query)[0]['json_agg'], adapter: nil, serializer: nil
end

