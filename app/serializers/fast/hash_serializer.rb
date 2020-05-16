module Fast
  class HashSerializer
    include FastJsonapi::ObjectSerializer

    set_id do |obj|
      obj['id']
    end

    attribute :latitude do |obj|
      obj['latitude']
    end

    attribute :longitude do |obj|
      obj['longitude']
    end
  end
end
