module VPS
  class CLI < Thor
    class Playbook
      class Tasks

        class InvalidTaskError < VPS::CLI::Error; end

        def self.available
          public_instance_methods(false) - [:run]
        end

        def initialize(tasks)
          @tasks = tasks.compact.freeze
        end

        def run!(state)
          state.scope do
            run(state, @tasks)
          end
        end

        def run(state, tasks)
          [tasks].flatten.compact.each do |task|
            case task
            when :continue
              # next
            when :abort
              raise Interrupt
            else
              name, options = resolve(task)
              if name
                if description = options[:description]
                  puts "\n== ".yellow + description.green
                end
                send(name, state, options)
              else
                raise InvalidTaskError, "Invalid task #{task.inspect}"
              end
            end
          end
        end

        def when(state, options)
          if state[options[:boolean]]
            run(state, options[:run])
          end
        end

        def confirm(state, options)
          answer = Ask.confirm(question(options)) ? "y" : "n"
          tasks = options[answer]
          set(state, options, answer)
          run(state, tasks)
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
          answer = Ask.input(question(options), default: options[:default])
          set(state, options, answer)
        end

        def execute(state, options)
          output = [options[:command]].flatten.inject(nil) do |_, command|
            command = state.resolve(command)
            puts "☕  ~> ".gray + command.yellow
            unless state.dry_run?
              start = Time.now
              `#{command}`.tap do |result|
                result = result.gsub(/^/, "   ").strip
                puts "   #{result}" unless result.blank?
                puts "   #{(Time.now - start).round(3)}s".gray
              end
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

        def playbook(state, options)
          Playbook.run(options[:playbook], state)
        end

        def print(state, options)
          puts state.resolve(options[:message])
        end

      private

        def resolve(task)
          if task.is_a?(Hash)
            task = task.with_indifferent_access
            name = task.delete(:task).to_sym
            if Tasks.available.include?(name)
              [name, task]
            end
          end
        end

          def question(options)
            (options[:indent] == false ? "" : "   ") + options[:question]
          end

        def set(state, options, answer)
          if as = options[:as]
            state[as] = answer
          end
        end

      end
    end
  end
end
