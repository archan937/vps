require "vps/version"

module VPS
  extend self

  ROOT = File.expand_path("#{__FILE__}/../..")
  PLAYBOOKS = "#{ROOT}/playbooks"
  TEMPLATES = "#{ROOT}/templates"

  def read_config(host, key = nil)
    if File.exists?(path = config_path(host))
      config = YAML.load_file(path)
      with_indifferent_access(key ? config[key] : config)
    elsif key.nil?
      with_indifferent_access({
        :user => nil,
        :tool => nil,
        :upstreams => []
      })
    end
  end

  def write_config(host, changes)
    config = read_config(host) || {}
    changed = false

    changes.each do |key, value|
      if config[key] != value
        config[key] = value
        changed = true
      end
    end

    if changed
      path = config_path(host)
      config = JSON.parse(config.to_json)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, config.to_yaml)
    end
  end

  def config_path(host, path = "config.yml")
    File.expand_path("~/.vps/#{host}/#{path}")
  end

  def template(path)
    File.read("#{TEMPLATES}/#{path}")
  end

private

  def with_indifferent_access(object)
    case object
    when Hash
      object.inject({}.with_indifferent_access) do |hash, (key, value)|
        hash[key] = with_indifferent_access(value)
        hash
      end
    when Array
      object.collect{|item| with_indifferent_access(item)}
    else
      object
    end
  end

end
