module VPS
  class CLI < Thor
    class Service < Thor

      SERVICES = "#{VPS::ROOT}/config/services.yml"

      desc "add HOST [SERVICE]", "Add service to host configuration"
      def add(host, service = nil)
        config = VPS.read_config(host)

        unless service
          list = services.keys.sort - config[:services].keys
          service = list[Ask.list("Which service to you want to add?", list)]
        end

        if !config[:services].include?(service) && (yml = services[service])
          list = tags(yml[:image] || "library/#{service}")
          tag = list[Ask.list("Choose which tag to use", list)]
          image = "#{yml[:image] || service}:#{tag}"

          yml, volumes = finalize_config(yml)
          config[:services][service] = {:image => image}.merge(yml)
          config[:volumes].concat(volumes).uniq!

          VPS.write_config(host, config)
        end
      end

      desc "remove HOST SERVICE", "Remove service from host configuration"
      def remove(host, service = nil)
        #
      end

      desc "list HOST", "List services of host configuration"
      def list(host)
        #
      end

    private

      def services
        @services ||= with_indifferent_access(YAML.load_file(SERVICES))
      end

      def tags(image)
        uri = URI.parse("https://registry.hub.docker.com/v2/repositories/#{image}/tags/")
        tags = JSON.parse(Net::HTTP.get(uri))["results"]
        tags.collect{|tag| tag["name"]}.sort{|a, b| (a == "latest") ? -1 : (b <=> a)}
      end

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

      def finalize_config(config)
        config.delete(:image)
        if config[:environment]
          config[:environment] = config[:environment].inject({}) do |env, variable|
            env[variable] = Ask.input(variable)
            env
          end
        end
        volumes = (config[:volumes] || []).collect do |volume|
          volume.split(":")[0]
        end
        [config, volumes]
      end

    end
  end
end
