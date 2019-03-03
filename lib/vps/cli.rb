require "yaml"
require "thor"
require "inquirer"
require "net/ssh"

require "active_support/dependencies/autoload"
require "active_support/number_helper"
require "active_support/core_ext/string/inflections"

require "vps/cli/playbook"
require "vps"

module VPS
  class CLI < Thor

    class Error < StandardError; end

    Playbook.all.each do |playbook|
      desc playbook.usage, playbook.description
      define_method playbook.command do |host|
        playbook.run!(host, options)
      end
    end

    desc "-v, [--version]", "Show VPS version number"
    map %w(-v --version) => :version
    def version
      puts "VPS #{VPS::VERSION}"
    end

  private

    def method_missing(method, *_args)
      raise Error, "Unrecognized command \"#{method}\". Please consult `vps help`."
    end

  end
end
