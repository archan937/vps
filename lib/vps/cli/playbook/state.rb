module VPS
  class CLI < Thor
    class Playbook
      class State

        class AuthenticationFailedError < VPS::CLI::Error; end
        class SSHMock
          def exec!(command)
            case command
            when "cat /etc/lsb-release"
              <<-LSB
              DISTRIB_ID=Ubuntu
              DISTRIB_RELEASE=18.04
              DISTRIB_CODENAME=bionic
              DISTRIB_DESCRIPTION="Ubuntu 18.04.2 LTS"
              LSB
            when "pwd"
              "/home/myapp"
            else
              raise "Encountered unexpected command: #{command}"
            end
          end
        end

        SERVER_VERSION = "SERVER_VERSION"

        def initialize(hash = {})
          @stack = [hash.with_indifferent_access]
        end

        def dry_run?
          !!fetch(:d) || skip?
        end

        def skip?
          !!fetch(:_skip_)
        end

        def scope(constants = {})
          stack.unshift(constants.with_indifferent_access)
          constants.keys.each do |key|
            self[key] = resolve(self[key])
          end
          yield
          stack.shift
        end

        def fetch(key, default = nil)
          stack.each do |hash|
            return hash[key] if hash.key?(key)
          end
          default
        end

        def [](path)
          to_domain = !!(path = path.dup).gsub!("domain:", "") if path.is_a?(String)
          path.to_s.split(".").inject(self) do |hash, key|
            (hash || {}).fetch(key)
          end.tap do |value|
            if to_domain && value
              if (domain = (value[:domains] || ["-"]).first)
                return domain.gsub(/https?:\/\//, "")
              end
            end
          end
        end

        def []=(key, value)
          stack.first[key] = value
        end

        def to_binding(object = self)
          case object
          when State
            keys = stack.collect(&:keys).flatten.uniq
            keys.inject({state: object}) do |hash, key|
              hash[key] = to_binding(self[key])
              hash
            end
          when Hash
            hash = object.inject({}) do |hash, (key, value)|
              hash[key] = to_binding(resolve(value))
              hash
            end
            OpenStruct.new(hash)
          when Array
            object.collect{|object| to_binding(object)}
          else
            object
          end
        end

        def resolve(arg)
          if arg.is_a?(String)
            if arg.match(/^<<\s*(.*?)\s*>>$/)
              self[$1]
            else
              arg.gsub(/\{\{(\{?)\s*(.*?)\s*\}\}\}?/) do
                value = self[$2]
                ($1 == "{") ? value.inspect : value
              end
            end
          else
            arg
          end
        end

        def execute(command, user = nil)
          if user
            command = "sudo -u #{user} -H sh -c #{command.inspect}"
          end
          puts "🏄‍♀️ ~> ".gray + command.yellow
          if dry_run?
            puts "   skipped".gray if skip?
          else
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

        def home_directory
          ssh.exec!("pwd").strip
        end

        def server_version
          release = ssh.exec!("cat /etc/lsb-release")

          distribution = release.match(/DISTRIB_ID=(.*)/)[1].underscore
          release = release.match(/DISTRIB_RELEASE=(.*)/)[1]

          [distribution, release].join("-")
        end

      private

        def stack
          @stack
        end

        def ssh
          if dry_run?
            SSHMock.new
          else
            Net::SSH.start(fetch(:host), fetch(:user))
          end
        rescue StandardError => e
          raise AuthenticationFailedError, e.message
        end

      end
    end
  end
end
