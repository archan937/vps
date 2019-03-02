require "thor"
require "vps"

module VPS
  class CLI < Thor

    desc "init", "Execute an initial server setup (including sudo user and firewall)"
    def init
      puts "Done."
    end

    desc "-v, [--version]", "Show VPS Control version number"
    map %w(-v --version) => :version
    def version
      puts "VPS Control #{VPS::VERSION}"
    end

  private

    def method_missing(method, *_args)
      raise Error, "Unrecognized command \"#{method}\". Please consult `vps help`."
    end

  end
end
