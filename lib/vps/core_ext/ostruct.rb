class OpenStruct
  def self.to_hash(object, hash = {})
    case object
    when OpenStruct then
      object.each_pair do |key, value|
        hash[key.to_s] = to_hash(value)
      end
      hash
    when Array then
      object.collect do |value|
        to_hash(value)
      end
    else
      object
    end
  end
end
