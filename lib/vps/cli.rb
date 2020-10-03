require "fileutils"
require "json"
require "yaml"
require "ostruct"
require "uri"
require "thor"
require "erubis"
require "inquirer"
require "net/http"
require "net/ssh"

require "active_support/dependencies/autoload"
require "active_support/core_ext/string/inflections"
require "active_support/core_ext/hash"
require "active_support/number_helper"

require "vps"
require "vps/core_ext/string"
require "vps/core_ext/ostruct"
require "vps/cli/service"
require "vps/cli/upstream"
require "vps/cli/domain"
require "vps/cli/playbook"

module VPS
  class CLI < Thor

    class Error < StandardError; end

    Playbook.all.each do |playbook|
      desc playbook.usage, playbook.description
      playbook.options.each do |(name, options)|
        method_option name, options
      end
      define_method playbook.command do |*args|
        start = Time.now
        playbook.run!(args, options)
        puts "\nDone. ".cyan + "#{(Time.now - start).round(3)}s".gray
      end
    end

    desc "edit [HOST]", "Edit the VPS configuration(s)"
    def edit(host = nil)
      `#{ENV["EDITOR"]} #{VPS.config_path(host, "")}`
    end

    register(Upstream, "upstream", "upstream", "Manage host upstreams")
    register(Service, "service", "service", "Manage host services")
    register(Domain, "domain", "domain", "Manage upstream domains")

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
