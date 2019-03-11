module VPS
  class CLI < Thor
    class Playbook
      class State

        class AuthenticationFailedError < VPS::CLI::Error; end

        SERVER_VERSION = "SERVER_VERSION"

        def initialize(hash = {})
          @stack = [hash.with_indifferent_access]
          self[:dirname] = File.basename(Dir.pwd)
        end

        def dry_run?
          !!fetch(:d)
        end

        def scope(constants = {})
          stack.unshift(constants.with_indifferent_access)
          yield
          stack.shift
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

        def stack
          @stack
        end

        def ssh
          @ssh ||= Net::SSH.start(fetch(:host), fetch(:user))
        rescue StandardError => e
          raise AuthenticationFailedError, e.message
        end

      end
    end
  end
end
