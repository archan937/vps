module VPS
  class CLI < Thor
    class Playbook
      class Tasks

        class InvalidTaskError < VPS::CLI::Error; end

        def self.available
          public_instance_methods(false) - [:run]
        end

        def initialize(tasks)
          @tasks = [tasks].flatten.compact
        end

        def run(state)
          @tasks.collect do |task|
            case task
            when :continue # next
            when :abort
              raise Interrupt
            else
              run_task(state, task)
            end
          end
        end

        def run_tasks(state, options)
          tasks = (state.resolve(options[:tasks]) || []).compact
          Tasks.new(tasks).run(state)
        end

        def ensure(state, options)
          argument = state.resolve(options[:argument])

          if state[argument].blank?
            options[:fallbacks].each do |task|
              unless (value = run_task(state, task.merge(as: argument))).blank?
                set(state, argument, value)
                break
              end
            end
          end
        end

        def obtain_config(state, options)
          VPS.read_config(state[:host]).tap do |config|
            config.each do |key, value|
              set(state, key, value)
            end
          end
        end

        def read_config(state, options)
          VPS.read_config(state[:host], state.resolve(options[:key]))
        end

        def write_config(state, options)
          config = {}

          options[:config].each do |key, spec|
            spec = spec.with_indifferent_access if spec.is_a?(Hash)

            if spec.is_a?(Hash) && spec[:task]
              config[key] = run_task(state, spec)
            else
              config[key] = state.resolve(spec)
            end
          end

          unless state.dry_run?
            VPS.write_config(state[:host], config)
          end
        end

        def loop(state, options)
          if (collection = (state.resolve(options[:through]) || []).compact).any?
            puts_description(state, options)
            as = state.resolve(options[:as])
            collection.each do |item|
              state.scope({as => item}) do
                run_tasks(state, {:tasks => options[:run]})
              end
            end
          end
        end

        def when(state, options)
          pass = false

          if options.key?("boolean")
            pass = !!state[options[:boolean]]
          else
            value = options.key?("value") ? state[options[:value]] : options[:string]
            if options.key?("include")
              pass = state[options[:include]].include?(value)
            elsif options.key?("exclude")
              pass = !state[options[:exclude]].include?(value)
            end
          end

          scope = pass ? {} : {_skip_: true}

          state.scope(scope) do
            puts_description(state, options)
            run_tasks(state, {:tasks => options[:run]})
          end
        end

        def confirm(state, options)
          answer = Ask.confirm(question(options)) ? "y" : "n"
          tasks = options[answer]
          set(state, options, answer)
          run_tasks(state, {:tasks => tasks})
        end

        def select(state, options)
          list = state.resolve(options[:options])
          index = Ask.list(question(options), list)
          set(state, options, list[index])
        end

        def multiselect(state, options)
          names, labels, defaults = [], [], []

          options[:options].inject([names, labels, defaults]) do |_, (name, label)|
            default = true
            label = label.gsub(/ \[false\]$/) do
              default = false
              ""
            end
            names.push(name)
            labels.push(label)
            defaults.push(default)
          end

          selected = Ask.checkbox(question(options), labels, default: defaults)
          selected.each_with_index do |value, index|
            name = names[index]
            state[name] = value
          end
        end

        def input(state, options)
          answer = Ask.input(question(options), default: state.resolve(options[:default]))
          set(state, options, answer)
        end

        def generate_file(state, options)
          erb = VPS.read_template(state.resolve(options[:template]))
          template = Erubis::Eruby.new(erb)
          content = template.result(state.to_binding)

          unless state.dry_run?
            if target = state.resolve(options[:target])
              target = File.expand_path(target)
              FileUtils.mkdir_p(File.dirname(target))
              File.open(target, "w") do |file|
                file.write(content)
              end
            end
          end

          content
        end

        def execute(state, options)
          output = [options[:command]].flatten.inject(nil) do |_, command|
            command = state.resolve(command)
            puts "☕ ~> ".gray + command.yellow
            if state.dry_run?
              puts "   skipped".gray if state.skip?
            else
              start = Time.now
              result = []

              IO.popen(command).each do |data|
                unless data.blank?
                  data = data.split("\n").reject(&:blank?)
                  puts "   " + data.join("\n   ")
                  result.concat data
                end
              end

              puts "   #{(Time.now - start).round(3)}s".gray
              result.join("\n")
            end
          end
          set(state, options, output)
        end

        def remote_execute(state, options)
          user = state.resolve(options[:user])
          output = [options[:command]].flatten.inject(nil) do |_, command|
            command = state.resolve(command)
            state.execute(command, user)
          end
          set(state, options, output)
        end

        def upload(state, options)
          host = state[:host]

          file = state.resolve(options[:file])
          remote_path = options[:remote_path] ? state.resolve(options[:remote_path]) : file
          file = "-r #{file}" if File.directory?(file)

          return if file.blank?

          remote_path = remote_path.gsub("~", state.home_directory)

          remote_execute(state, {:command => "mkdir -p #{File.dirname(remote_path)}"})
          execute(state, {:command => "scp #{file} #{host}:#{remote_path} > /dev/tty"})
        end

        def sync(state, options)
          host = state[:host]

          directory = state.resolve(options[:directory])
          remote_path = options[:remote_path] ? state.resolve(options[:remote_path]) : directory

          return if directory.blank?

          remote_path = remote_path.gsub("~", state.home_directory)

          remote_execute(state, {:command => "mkdir -p #{File.dirname(remote_path)}"})
          execute(state, {:command => "rsync #{options[:options]} #{directory} #{host}:#{remote_path} > /dev/tty"})
        end

        def playbook(state, options)
          Playbook.run(state.resolve(options[:playbook]), state)
        end

        def print(state, options)
          puts state.resolve(options[:message])
        end

      private

        def run_task(state, task)
          name, options = derive_task(task)
          if name
            puts_description(state, options) unless [:when, :loop].include?(name)
            send(name, state, options)
          else
            raise InvalidTaskError, "Invalid task #{task.inspect}"
          end
        end

        def derive_task(task)
          if task.is_a?(Hash)
            task = task.with_indifferent_access
            name = task.delete(:task).to_sym
            if Tasks.available.include?(name)
              [name, task]
            end
          end
        end

        def puts_description(state, options)
          if description = state.resolve(options[:description])
            puts "\n== ".yellow + description.green
          end
        end

        def question(options)
          (options[:indent] == false ? "" : "   ") + options[:question]
        end

        def set(state, as, value)
          if key = (as.is_a?(Hash) ? as[:as] : as)
            state[key] = value
          end
        end

      end
    end
  end
end
