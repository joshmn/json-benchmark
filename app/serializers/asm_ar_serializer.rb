module HashSerializer
  def read_attribute_for_serialization(attr)
    object[attr.to_s] || super
  end
end

class AsmArSerializer < ::ActiveModel::Serializer
  include HashSerializer
  attributes :id, :latitude, :longitude
end
