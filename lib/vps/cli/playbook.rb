require "vps/cli/playbook/state"
require "vps/cli/playbook/tasks"

module VPS
  class CLI < Thor
    class Playbook

      class NotFoundError < VPS::CLI::Error; end

      YML = ".yml"

      attr_reader :command

      def self.all
        Dir["#{VPS::PLAYBOOKS}/*#{YML}"].collect do |playbook|
          command = File.basename(playbook, YML)
          new(playbook, command)
        end
      end

      def self.run(playbook, state)
        playbook = File.expand_path(playbook, VPS::PLAYBOOKS)

        if File.directory?(playbook)
          playbook += "/#{state.server_version}"
        end
        unless File.extname(playbook) == YML
          playbook += YML
        end

        new(playbook).run(state)
      end

      def initialize(playbook, command = nil)
        unless File.exists?(playbook)
          raise NotFoundError, "Could not find playbook #{playbook.inspect}"
        end

        @playbook = {"constants" => {}}.merge(YAML.load_file(playbook))
        unless (playbooks = Dir[playbook.gsub(/\.\w+$/, "/*")].collect{|yml| File.basename(yml, ".yml")}).empty?
          @playbook["constants"]["playbooks"] = playbooks
        end

        @command = command
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
        options = (playbook["options"] || {}).inject({}) do |hash, (key, value)|
          hash[key.to_sym] = value.symbolize_keys
          hash
        end
        options[:d] = {:type => :boolean, :aliases => "dry-run"}
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

        self.options.each do |(name, opts)|
          if opts[:aliases]
            state[opts[:aliases].underscore] = state[name]
          end
        end

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
