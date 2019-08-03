require "fileutils"
require "json"
require "yaml"
require "ostruct"
require "thor"
require "erubis"
require "inquirer"
require "net/ssh"

require "active_support/dependencies/autoload"
require "active_support/core_ext/string/inflections"
require "active_support/core_ext/hash"
require "active_support/number_helper"

require "vps/core_ext/string"
require "vps/cli/playbook"
require "vps"

module VPS
  class CLI < Thor

    class Error < StandardError; end

    Playbook.all.each do |playbook|
      desc playbook.usage, playbook.description
      method_options playbook.options if playbook.options
      define_method playbook.command do |*args|
        start = Time.now
        playbook.run!(args, options)
        puts "\nDone. ".cyan + "#{(Time.now - start).round(3)}s".gray
      end
    end

    desc "edit HOST", "Edit the VPS configuration file"
    def edit(host)
      `open #{VPS.config_path(host)}`
    end

    class Upstream < Thor
      desc "add HOST PATH", "Add upstream to host configuration (option: --name)"
      method_option :name
      def add(host, path)
        config = VPS.read_config(host)
        config[:upstreams].push({
          :name => options[:name] || File.basename(path),
          :path => path,
          :domains => []
        })
        VPS.write_config(host, config)
      end

      desc "remove HOST UPSTREAM", "Remove upstream from host configuration"
      def remove(host, name)
        config = VPS.read_config(host)
        config[:upstreams].reject!{|upstream| upstream[:name] == name}
        VPS.write_config(host, config)
      end

      desc "list HOST", "List upstreams of host configuration"
      def list(host)
        config = VPS.read_config(host)
        upstreams = config[:upstreams].collect do |upstream|
          "* #{upstream[:name]} (#{upstream[:path].gsub(Dir.home, "~")})"
        end.sort
        puts upstreams
      end
    end

    class Domain < Thor
      desc "add HOST:UPSTREAM DOMAIN", "Add domain to host upstream"
      def add(host_and_upstream, domain)
        return unless domain.match(/^https?:\/\/([a-z0-9\-]{2,}\.)+[a-z]{2,}$/)

        host, name = host_and_upstream.split(":")
        config = VPS.read_config(host)

        if (upstream = config[:upstreams].detect{|upstream| upstream[:name] == name})
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

      desc "list HOST[:UPSTREAM]", "List domains of host (:upstream optional)"
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

    register(Upstream, "upstream", "upstream", "Manage host upstreams")
    register(Domain, "domain", "domain", "Manage upstream domains")

    desc "-v, [--version]", "Show VPS version number"
    map %w(-v --version) => :version
    def version
      puts "vps #{VPS::VERSION}"
    end

  private

    def method_missing(method, *_args)
      raise Error, "Unrecognized command \"#{method}\". Please consult `vps help`."
    end

  end
end
