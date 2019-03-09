require "yaml"
require "thor"
require "inquirer"
require "net/ssh"

require "active_support/dependencies/autoload"
require "active_support/core_ext/string/inflections"
require "active_support/core_ext/hash"
require "active_support/number_helper"

require "vps/core_ext/string"
require "vps/cli/playbook"
require "vps"

module VPS
  class CLI < Thor

    class Error < StandardError; end

    Playbook.all.each do |playbook|
      desc playbook.usage, playbook.description
      method_options playbook.options if playbook.options
      define_method playbook.command do |*args|
        start = Time.now
        playbook.run!(args, options)
        puts "\nDone. ".cyan + "#{(Time.now - start).round(3)}s".gray
      end
    end

    desc "-v, [--version]", "Show VPS version number"
    map %w(-v --version) => :version
    def version
      puts "vps #{VPS::VERSION}"
    end

  private

    def method_missing(method, *_args)
      raise Error, "Unrecognized command \"#{method}\". Please consult `vps help`."
    end

  end
end
