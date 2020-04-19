module Fast
  class HomeSerializer
    include FastJsonapi::ObjectSerializer
    attributes :id, :latitude, :longitude
  end
end
