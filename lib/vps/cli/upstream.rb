module VPS
  class CLI < Thor
    class Upstream < Thor

      desc "add HOST[:UPSTREAM] PATH", "Add upstream to host configuration"
      def add(host_and_optional_upstream, path)
        host, name = host_and_optional_upstream.split(":")
        config = VPS.read_config(host)
        path = File.expand_path(path)

        unless config[:upstreams].any?{|upstream| upstream[:name] == name}
          spec = derive_upstream(path)
          config[:upstreams].push(spec.merge({
            :name => name || File.basename(path),
            :path => path,
            :compose => {
              :container_name => name || File.basename(path)
            }
          }))
          VPS.write_config(host, config)
        end
      end

      desc "remove HOST[:UPSTREAM]", "Remove upstream from host configuration"
      def remove(host_and_optional_upstream)
        host, name = host_and_optional_upstream.split(":")
        config = VPS.read_config(host)

        unless name
          list = config[:upstreams].collect{|upstream| upstream[:name]}.sort
          name = list[Ask.list("Which upstream do you want to remove?", list)]
        end

        if config[:upstreams].reject!{|upstream| upstream[:name] == name}
          VPS.write_config(host, config)
        end
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
          {
            type: type,
            elixir_version: `cd #{path} && mix run -e "System.version() |> IO.puts()" | tail -n 1`.strip,
            port: (type == "phoenix") ? 4000 : `cd #{path} && mix run -e ":ranch.info |> hd() |> elem(0) |> :ranch.get_port() |> IO.puts()" | tail -n 1`.strip.to_i
          }
        elsif Dir["#{path}/Gemfile"].any?
          lines = `cd #{path} && BUNDLE_GEMFILE=#{path}/Gemfile bundle list`.split("\n")
          type = %w(rails rack).detect{|gem| lines.any?{|line| line.include?("* #{gem} (")}}
          {
            type: type,
            ruby_version: `$SHELL -l -c 'cd #{path} && ruby -e "puts RUBY_VERSION"'`.strip,
            bundler_version: `$SHELL -l -c 'cd #{path} && bundle -v'`.split.last,
            port: (type == "rails" ? 3000 : 9292) # :'(
          }.tap do |spec|
            if type == "rails"
              spec[:nginx] = {
                root: "/opt/app/public",
                try_files: true,
                proxy_redirect: "off"
              }
            end
          end
        elsif Dir["#{path}/package.json"].any?
          tmpfile = "#{Dir.tmpdir}/vps-debug.log"
          pid = spawn("cd #{path} && npm start", :out => tmpfile, :err => "/dev/null")
          Process.detach(pid)
          sleep 5
          `ps aux | grep -e "no[d]e #{path}"`.strip.split("\n").collect do |line|
            `kill -9 #{line.split(" ")[1]}`
          end
          port = File.read(tmpfile).match(/on port (\d+)/).captures.first.to_i
          {
            type: "node",
            node_version: `$SHELL -l -c 'cd #{path} && node -v'`.match(/[\d\.?]+/).to_s,
            port: port
          }
        end
      end

    end
  end
end
