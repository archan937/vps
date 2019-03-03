require "vps/cli/playbook/state"
require "vps/cli/playbook/tasks"

module VPS
  class CLI < Thor
    class Playbook

      class NotFoundError < CLI::Error; end
      class MissingConfirmationError < CLI::Error; end

      DIRECTORY = File.expand_path(File.join(__FILE__, "../../../../playbooks"))
      EXTNAME = ".yml"

      attr_reader :command

      def self.all
        Dir["#{DIRECTORY}/*#{EXTNAME}"].collect do |playbook|
          command = File.basename(playbook, EXTNAME)
          new(playbook, command)
        end
      end

      def self.run(playbook, state)
        playbook = File.expand_path(playbook, DIRECTORY)

        if File.directory?(playbook)
          playbook += "/#{state.server_version}"
        end
        unless File.extname(playbook) == EXTNAME
          playbook += EXTNAME
        end

        new(playbook).run(state)
      end

      def initialize(playbook, command = nil)
        unless File.exists?(playbook)
          raise NotFoundError, "Could not find playbook #{playbook.inspect}"
        end

        @playbook = YAML.load_file(playbook)
        @command = command

        assert_confirmation!
      end

      def run!(host, options)
        run(State.new(host, playbook, options))
      end

      def run(state)
        Tasks.new(tasks).run!(state)
      end

      def description
        playbook["description"]
      end

      def usage
        [@command, "[HOST]"].join(" ")
      end

      def options
        options = playbook["options"] || {}
        options[%w(-d --dry-run)] = :boolean
        options
      end

      def tasks
        tasks = [playbook["tasks"]].flatten.compact

        if requires_confirmation?
          tasks.unshift({
            "task" => :confirm,
            "question" => playbook["confirm"],
            "n" => :abort
          })
        end

        if @command
          tasks.push({
            "task" => :print,
            "message" => "Done."
          })
        end

        tasks
      end

    private

      def playbook
        @playbook
      end

      def requires_confirmation?
        playbook["confirm"].to_s.strip != ""
      end

      def assert_confirmation!
        if @command && !requires_confirmation?
          raise MissingConfirmationError, "Missing confirmation for #{playbook.inspect}"
        end
      end

    end
  end
end
