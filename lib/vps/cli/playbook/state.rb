module VPS
  class CLI < Thor
    class Playbook
      class State

        SERVER_VERSION = "SERVER_VERSION"

        def initialize(host, playbook, options)
          @host = host
          @user = playbook["user"]
          @stack = [resolve(playbook, options)]
        end

        def scope
          stack.unshift({})
          yield
          stack.shift
        end

        def [](key)
          stack.each do |hash|
            return hash[key] if hash.key?(key)
          end
          nil
        end

        def []=(key, value)
          stack.first[key] = value
        end

        def execute(command)
          command = command.gsub(/\{\{(.*?)\}\}/) { self[$1] }
          ssh.exec!(command)
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

        def resolve(playbook, options)
          {}
        end

      end
    end
  end
end
