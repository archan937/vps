# VPS

Manage your Virtual Private Server using a user-friendly CLI

**NOTE: This is an experimental project**

## Installation

Run the following command to install `VPS`:

    $ gem install "vps"

## Usage

VPS is a command-line-interface, you can print help instructions:

    $ vps help
    Commands:
      vps -v, [--version]                     # Show VPS version number
      vps deploy HOST [TOOL]                  # Deploy web application to the server
      vps domain                              # Manage upstream domains
      vps domain add HOST:UPSTREAM DOMAIN     # Add domain to host upstream
      vps domain help [COMMAND]               # Describe subcommands or one specific subcommand
      vps domain list HOST[:UPSTREAM]         # List domains of host (:upstream is optional)
      vps domain remove HOST:UPSTREAM DOMAIN  # Remove domain from host upstream
      vps edit HOST                           # Edit the VPS configuration file
      vps help [COMMAND]                      # Describe available commands or one specific command
      vps init HOST                           # Execute an initial server setup
      vps install HOST TOOL                   # Install software on the server
      vps upstream                            # Manage host upstreams
      vps upstream add HOST[:UPSTREAM] PATH   # Add upstream to host configuration (:upstream is optional)
      vps upstream help [COMMAND]             # Describe subcommands or one specific subcommand
      vps upstream list HOST                  # List upstreams of host configuration
      vps upstream remove HOST:UPSTREAM       # Remove upstream from host configuration

### Deploying an Elixir Plug application to a totally clean Ubuntu server

Let's say the SSH host is called `silver_surfer` and that the application is located at `~/Sources/spider_web`. Just execute the following commands:

    $ vps init silver_surfer
    $ vps install silver_surfer docker
    $ vps upstream add silver_surfer ~/Sources/spider_web
    $ vps domain add silver_surfer:spider_web http://spider.web
    $ vps deploy silver_surfer

Et voilà. Your awesome Elixir Plug website is online, powered by Docker and Nginx! :D

## Contact me

For support, remarks and requests, please mail me at [pm_engel@icloud.com](mailto:pm_engel@icloud.com).

## License

Copyright (c) 2019 Paul Engel, released under the MIT license

http://github.com/archan937 – http://twitter.com/archan937 – pm_engel@icloud.com

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
