module VPS
  class CLI < Thor
    class Domain < Thor

      desc "add HOST:UPSTREAM DOMAIN [EMAIL]", "Add domain to host upstream (email required for https://)"
      def add(host_and_upstream, domain, email = nil)
        return unless domain.match(/^https?:\/\/([a-z0-9\-]{2,}\.)+[a-z]{2,}$/)

        host, name = host_and_upstream.split(":")
        config = VPS.read_config(host)

        if (upstream = config[:upstreams].detect{|upstream| upstream[:name] == name})
          upstream[:email] = email if email
          upstream[:domains].push(domain).uniq!
        end

        VPS.write_config(host, config)
      end

      desc "remove HOST:UPSTREAM DOMAIN", "Remove domain from host upstream"
      def remove(host_and_upstream, domain)
        host, name = host_and_upstream.split(":")
        config = VPS.read_config(host)

        if (upstream = config[:upstreams].detect{|upstream| upstream[:name] == name})
          upstream[:domains].delete(domain)
        end

        VPS.write_config(host, config)
      end

      desc "list HOST[:UPSTREAM]", "List domains of host (:upstream is optional)"
      def list(host_and_optional_upstream)
        host, name = host_and_optional_upstream.split(":")
        config = VPS.read_config(host)

        domains = config[:upstreams].collect do |upstream|
          if name.nil? || upstream[:name] == name
            upstream[:domains]
              .collect{|domain| "  ~> #{domain}"}
              .unshift("* #{upstream[:name]}:")
          end
        end.flatten.compact

        puts domains
      end

    end
  end
end
