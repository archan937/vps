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
      `#{ENV["EDITOR"]} #{VPS.config_path(host, "")}`
    end

    class Upstream < Thor
      desc "add HOST[:UPSTREAM] PATH", "Add upstream to host configuration (:upstream is optional)"
      def add(host_and_optional_upstream, path)
        host, name = host_and_optional_upstream.split(":")
        config = VPS.read_config(host)
        path = File.expand_path(path)
        unless config[:upstreams].any?{|upstream| upstream[:name] == name}
          type, tool_version, port = derive_upstream(path)
          config[:upstreams].push({
            :name => name || File.basename(path),
            :path => path,
            :type => type,
            :tool_version => tool_version,
            :port => port,
            :domains => []
          })
        end
        VPS.write_config(host, config)
      end

      desc "remove HOST:UPSTREAM", "Remove upstream from host configuration"
      def remove(host_and_upstream)
        host, name = host_and_upstream.split(":")
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

    private

      def derive_upstream(path)
        if Dir["#{path}/mix.exs"].any?
          elixir = <<-ELIXIR
            Application.started_applications()
            |> Enum.reduce([], fn {name, _desc, _version}, acc ->
              if(name in [:phoenix, :plug], do: [name | acc], else: acc)
            end)
            |> Enum.sort()
            |> Enum.at(0)
            |> IO.puts()
          ELIXIR
          type = `cd #{path} && mix run -e "#{elixir.strip.gsub(/\n\s+/, " ")}" | tail -n 1`.strip
          [
            type,
            `cd #{path} && mix run -e "System.version() |> IO.puts()" | tail -n 1`.strip,
            (type == "phoenix") ? 4000 : `cd #{path} && mix run -e ":ranch.info |> hd() |> elem(0) |> :ranch.get_port() |> IO.puts()" | tail -n 1`.strip.to_i
          ]
        elsif Dir["#{path}/Gemfile"].any?
          lines = `cd #{path} && BUNDLE_GEMFILE=#{path}/Gemfile bundle list`.split("\n")
          type = %w(rails rack).detect{|gem| lines.any?{|line| line.include?("* #{gem} (")}}
          [
            type,
            `$SHELL -l -c 'cd #{path} && ruby -e "puts RUBY_VERSION"'`.strip,
            (type == "rails" ? 3000 : 9292) # :'(
          ]
        end
      end
    end

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
