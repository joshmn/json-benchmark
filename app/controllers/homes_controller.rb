class HomesController < ApplicationController
  around_action :benchmark!

  def index
    @types = ['asm', 'asm-ar', 'fastjson', 'map', 'map-ar', 'map-oj', 'map-oj-ar', 'pg']

    homes = Home.select(:id, :latitude, :longitude).limit(params[:limit] || 10000)

    case params[:via]
    when 'asm'
      return render json: ActiveModelSerializers::SerializableResource.new(homes, each_serializer: AsmSerializer).to_json
    when 'asm-ar'
      homes = Home.connection.exec_query(homes.to_sql)
      return render json: ActiveModel::Serializer::CollectionSerializer.new(homes, serializer: AsmArSerializer).to_json
    when 'fastjson'
      return render json: homes.map { |home| Fast::HomeSerializer.new(home) }.to_json
    when 'map'
      return render json: homes.map { |home| { id: home.id, latitude: home.latitude, longitude: home.longitude } }.to_json
    when 'map-ar'
      return render json: Home.connection.exec_query(homes.to_sql).to_a.to_json, adapter: nil
    when 'map-oj'
      return render json: Oj.dump(homes.map { |home| home.as_json }), adapter: nil
    when 'map-oj-ar'
      return render json: Oj.dump(Home.connection.exec_query(homes.to_sql).to_a), adapter: nil
    when 'map-oj-ar-execute'
      return render json: Oj.dump(Home.connection.execute(homes.to_sql).to_a), adapter: nil
    when 'pg'
      query = "select json_agg(json_build_object('id', id, 'latitude', CAST(latitude AS TEXT), 'longitude', CAST(longitude AS TEXT))) from (#{homes.to_sql}) home;"
      return render json: Home.connection.exec_query(query)[0]['json_agg'], adapter: nil, serializer: nil
    end
  end

  private

  def benchmark!
    self.benchmark(request.path) do
      yield
    end
  end
end
