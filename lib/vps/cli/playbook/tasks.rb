module VPS
  class CLI < Thor
    class Playbook
      class Tasks

        class InvalidTaskError < CLI::Error; end

        def self.available
          public_instance_methods(false) - [:run]
        end

        def initialize(tasks)
          @tasks = tasks.compact.freeze
        end

        def run(state, tasks = nil)
          [tasks || @tasks].flatten.each do |task|
            case task
            when :continue
              # next
            when :abort
              raise Interrupt
            else
              name, options = resolve(task)
              if name
                send(name, state, options)
              else
                raise InvalidTaskError, "Invalid task #{task.inspect}"
              end
            end
          end
        end

        def confirm(state, options)
          answer = Ask.confirm(options["question"]) ? "y" : "n"
          tasks = options[answer]
          run(state, tasks)
        end

        def playbook(state, options)
          Playbook.run(options["playbook"], state)
        end

      private

        def resolve(task)
          if task.is_a?(Hash)
            name = task["task"]
            if Tasks.available.include?(name)
              options = task.reject{|key, value| key == "task"}
              [name, options]
            end
          end
        end

      end
    end
  end
end
