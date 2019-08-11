require "vps/version"

module VPS
  extend self

  ROOT = File.expand_path("#{__FILE__}/../..")
  PLAYBOOKS = "#{ROOT}/playbooks"
  TEMPLATES = "#{ROOT}/templates"

  def config_path(host, path = "config.yml")
    File.expand_path("~/.vps/#{host}/#{path}")
  end

  def read_template(path)
    File.read("#{TEMPLATES}/#{path}")
  end

  def read_config(host, key = nil)
    config =
      if File.exists?(path = config_path(host))
        YAML.load_file(path)
      elsif key.nil?
        {
          :user => nil,
          :tool => nil,
          :release_path => nil,
          :services => nil,
          :upstreams => nil,
          :volumes => nil,
          :preload => nil,
          :postload => nil
        }
      end

    if config
      config = with_indifferent_access(config)
      if key
        with_indifferent_access(config[key])
      else
        config[:services] ||= {}
        config[:upstreams] ||= []
        config[:volumes] ||= []
        config
      end
    end
  end

  def write_config(host, changes)
    config = read_config(host) || {}
    changed = false

    %w(services upstreams volumes).each do |key|
      changes[key] = nil if changes[key].empty?
    end

    changes.each do |key, value|
      if !config.include?(key) || (config[key] != value)
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
