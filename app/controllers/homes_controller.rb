class HomesController < ApplicationController
  around_action :benchmark!
  TYPES =  [
      'nothing', 'nothing_oj',
      'nothing_map', 'nothing_map_oj',
      'asm', 'asm_oj',
      'asm_exec_query', 'asm_exec_query_oj',
      'asm_execute', 'asm_execute_oj',
      'fast', 'fast_oj',
      'fast_map', 'fast_map_oj',
      'fast_exec_query', 'fast_exec_query_oj',
      'fast_execute', 'fast_execute_oj',
      'execute', 'execute_oj',
      'execute_map', 'execute_map_oj',
      'exec_query', 'exec_query_oj',
      'exec_query_map', 'exec_query_map_oj',
      'jbuilder', 'jbuilder_map_oj',
      'pg']

  def index
    @types = TYPES

    homes = Home.select(:id, :latitude, :longitude).limit(params[:limit] || 100)

    case params[:via]
    when 'nothing'
      return render json: homes, adapter: nil, serializer: nil
    when 'nothing_oj'
      return render json: Oj.dump(homes.as_json, mode: :compat), adapter: nil, serializer: nil
    when 'nothing_map'
      return render json: homes.map { |home| { id: home.id, latitude: home.latitude, longitude: home.longitude } }, adapter: nil, serializer: nil
    when 'nothing_map_oj'
      return render json: Oj.dump(homes.map { |home| { id: home.id, latitude: home.latitude, longitude: home.longitude }}, mode: :compat), adapter: nil, serializer: nil
    when 'asm'
      return render json: ActiveModelSerializers::SerializableResource.new(homes, each_serializer: AsmSerializer).to_json
    when 'asm_oj'
      return render json: Oj.dump(ActiveModelSerializers::SerializableResource.new(homes, each_serializer: AsmSerializer).as_json, mode: :compat)
    when 'asm_exec_query'
      homes = Home.connection.exec_query(homes.to_sql)
      return render json: ActiveModel::Serializer::CollectionSerializer.new(homes, serializer: AsmArSerializer).to_json
    when 'asm_exec_query_oj'
      homes = Home.connection.exec_query(homes.to_sql)
      return render json: Oj.dump(ActiveModel::Serializer::CollectionSerializer.new(homes, serializer: AsmArSerializer).as_json, mode: :compat)
    when 'asm_execute'
      homes = Home.connection.execute(homes.to_sql).to_a
      return render json: ActiveModel::Serializer::CollectionSerializer.new(homes, serializer: AsmArSerializer)
    when 'asm_execute_oj'
      homes = Home.connection.execute(homes.to_sql).to_a
      return render json: Oj.dump(ActiveModel::Serializer::CollectionSerializer.new(homes, serializer: AsmArSerializer).as_json, mode: :compat)
    when 'fast'
      return render json: Fast::HomeSerializer.new(homes).to_json
    when 'fast_oj'
      return render json: Oj.dump(Fast::HomeSerializer.new(homes).serializable_hash, mode: :compat)
    when 'fast_map'
      return render json: homes.map { |home| Fast::HomeSerializer.new(home).serializable_hash }
    when 'fast_map_oj'
      return render json: Oj.dump(homes.map { |home| Fast::HomeSerializer.new(home).serializable_hash }, mode: :compat)
    when 'fast_exec_query'
      homes = Home.connection.exec_query(homes.to_sql)
      return render json: homes.to_a { |home| Fast::HomeSerializer.new(home).serializable_hash }
    when 'fast_exec_query_oj' # fix
      homes = Home.connection.exec_query(homes.to_sql)
      return render json: Oj.dump(homes.to_a.map { |home| Fast::HashSerializer.new(home) }, mode: :compat)
    when 'fast_execute'
      homes = Home.connection.execute(homes.to_sql)
      return render json: homes.to_a.map { |home| Fast::HashSerializer.new(home).serializable_hash }.to_json
    when 'fast_execute_oj' # fix
      homes = Home.connection.execute(homes.to_sql)
      return render json: Oj.dump(homes.map { |home| Fast::HashSerializer.new(home).serializable_hash }, mode: :compat)
    when 'jbuilder'
      return render json: Jbuilder.new { |json| json.array! homes, :id, :latitude, :longitude }.target!, adapter: nil, serializer: nil
    when 'jbuilder_map_oj'
      return render json: Oj.dump(Jbuilder.new { |json| json.array! homes, :id, :latitude, :longitude }.target!, mode: :compat), adapter: nil, serializer: nil
    when 'execute'
      return render json: Home.connection.execute(homes.to_sql).to_a.to_json, adapter: nil
    when 'execute_oj'
      return render json: Oj.dump(Home.connection.execute(homes.to_sql).to_a), adapter: nil
    when 'execute_map'
      return render json: Home.connection.execute(homes.to_sql).to_a.map { |home| {id: home['id'], latitude: home['latitude'], longitude: home['longitude'] } }.to_json, adapter: nil
    when 'execute_map_oj'
      return render json: Oj.dump(Home.connection.execute(homes.to_sql).to_a.map { |home| {id: home['id'], latitude: home['latitude'], longitude: home['longitude'] } }, mode: :compat), adapter: nil
    when 'exec_query'
      return render json: Home.connection.exec_query(homes.to_sql).to_a.to_json, adapter: nil
    when 'exec_query_oj'
      return render json: Oj.dump(Home.connection.exec_query(homes.to_sql).to_a), adapter: nil
    when 'exec_query_map'
      return render json: Home.connection.exec_query(homes.to_sql).to_a.map { |home| {id: home['id'], latitude: home['latitude'], longitude: home['longitude'] } }.to_json, adapter: nil
    when 'exec_query_map_oj'
      return render json: Oj.dump(Home.connection.exec_query(homes.to_sql).to_a.map { |home| {id: home['id'], latitude: home['latitude'], longitude: home['longitude'] } }, mode: :compat), adapter: nil
    when 'pg'
      query = "select json_agg(json_build_object('id', id, 'latitude', CAST(latitude AS TEXT), 'longitude', CAST(longitude AS TEXT))) from (#{homes.to_sql}) home;"
      return render json: Home.connection.exec_query(query)[0]['json_agg'], adapter: nil, serializer: nil
    else
      render plain: "hi"
    end
  end

  private

  def benchmark!
    report = MemoryProfiler.report do
      yield
    end
    Rails.logger.info("MEMSTAT: #{report.total_retained_memsize / 10_024} / #{report.total_allocated_memsize / 10_024}")
  end
end
