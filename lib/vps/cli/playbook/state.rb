module VPS
  class CLI < Thor
    class Playbook
      class State

        SERVER_VERSION = "SERVER_VERSION"

        def initialize(host, playbook, options)
          @host = host
          @user = playbook["user"]
          @stack = [options.with_indifferent_access]
        end

        def dry_run?
          !!fetch(:d)
        end

        def scope
          stack.unshift(HashWithIndifferentAccess.new)
          yield
          stack.shift
        end

        def resolve(string)
          string.gsub(/\{\{(\{?)\s*(.*?)\s*\}\}\}?/) do
            value = self[$2]
            ($1 == "{") ? value.inspect : value
          end if string
        end

        def fetch(key, default = nil)
          stack.each do |hash|
            return hash[key] if hash.key?(key)
          end
          default
        end

        def [](key)
          fetch(key)
        end

        def []=(key, value)
          stack.first[key] = value
        end

        def execute(command, user = nil)
          if user
            command = "sudo -u #{user} -H bash -c #{command.inspect}"
          end
          puts "🏄‍♀️  ~> ".gray + command.yellow
          unless dry_run?
            start = Time.now
            result = []

            channel = ssh.open_channel do |ch|
              ch.exec(command) do |ch|
                ch.on_data do |_, data|
                  unless data.blank?
                    data = data.split("\n").reject(&:blank?)
                    puts "   " + data.join("\n   ")
                    result.concat data
                  end
                end
              end
            end
            channel.wait

            puts "   #{(Time.now - start).round(3)}s".gray
            result.join("\n")
          end
        end

        def server_version
          @server_version ||= begin
            release = ssh.exec!("cat /etc/lsb-release")

            distribution = release.match(/DISTRIB_ID=(.*)/)[1].underscore
            release = release.match(/DISTRIB_RELEASE=(.*)/)[1]

            [distribution, release].join("-")
          end
        end

      private

        def ssh
          @ssh ||= Net::SSH.start(@host, @user)
        end

        def stack
          @stack
        end

      end
    end
  end
end
