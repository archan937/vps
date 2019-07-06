require "vps/cli/playbook/state"
require "vps/cli/playbook/tasks"

module VPS
  class CLI < Thor
    class Playbook

      class NotFoundError < VPS::CLI::Error; end

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

        if playbooks = Dir[playbook.gsub(/\.\w+$/, "/*.yml")].collect{|yml| File.basename(yml, ".yml")}
          @playbook["constants"] = constants.merge({"playbooks" => playbooks})
        end
      end

      def description
        playbook["description"]
      end

      def usage
        playbook["usage"] || arguments.collect(&:upcase).unshift(@command).join(" ")
      end

      def arguments
        playbook["arguments"] || []
      end

      def constants
        playbook["constants"] || {}
      end

      def options
        options = playbook["options"] || {}
        options[%w(-d --dry-run)] = :boolean
        options
      end

      def tasks
        @tasks ||= begin
          tasks = [playbook["tasks"]].flatten.compact

          if requires_confirmation?
            tasks.unshift({
              "task" => :confirm,
              "question" => playbook["confirm"],
              "indent" => false,
              "n" => :abort
            })
          end

          Tasks.new(tasks)
        end
      end

      def run!(args, options)
        hash = Hash[arguments.zip(args)]
        state = State.new(hash.merge(options))
        run(state)
      end

      def run(state)
        state.scope(constants) do
          tasks.run(state)
        end
      end

    private

      def playbook
        @playbook
      end

      def requires_confirmation?
        playbook["confirm"].to_s.strip != ""
      end

    end
  end
end
