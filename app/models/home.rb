class Home < ApplicationRecord
  def to_jbuilder
    Jbuilder.new do |home|
      home.id id
      home.latitude latitude
      home.longitude longitude
    end
  end
end
