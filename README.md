# VPS

Zero-config deployments of Plug, Phoenix, Rack and Rails apps on a clean Ubuntu server using Docker and Let's Encrypt

**NOTE: This is an experimental project**

## Introduction

Despite of having my fair share of experience in software development, hosting web applications has never really been my strongest skill set. So as a real programmer, I want to use a command line interface for easy deployments of my web applications (using HTTPS or not).

Important for me is not want to be locked onto a specific hosting provider and also, I want the server to be dispensable because "I know that my CLI has got my back".

So enter the Ruby gem `VPS` which makes it able to deploy my web application on a totally clean Ubuntu server by roughly just executing five simple commands :muscle:

## Installation

Run the following command to install `VPS`:

    $ gem install "vps"

## Usage

VPS is a command-line-interface, you can print help instructions:

    $ vps help
    Commands:
      vps -v, [--version]                          # Show VPS version number
      vps deploy HOST [TOOL]                       # Deploy web application to the server
      vps domain                                   # Manage upstream domains
      vps domain add HOST:UPSTREAM DOMAIN [EMAIL]  # Add domain to host upstream (email recommended for https)
      vps domain help [COMMAND]                    # Describe subcommands or one specific subcommand
      vps domain list HOST[:UPSTREAM]              # List domains of host
      vps domain remove HOST[:UPSTREAM] [DOMAIN]   # Remove domain from host upstream
      vps edit [HOST]                              # Edit the VPS configuration(s)
      vps help [COMMAND]                           # Describe available commands or one specific command
      vps init HOST                                # Execute an initial server setup
      vps install HOST [TOOL]                      # Install software on the server
      vps service                                  # Manage host services
      vps service add HOST [SERVICE]               # Add service to host configuration
      vps service help [COMMAND]                   # Describe subcommands or one specific subcommand
      vps service list HOST                        # List services of host configuration
      vps service remove HOST SERVICE              # Remove service from host configuration
      vps upstream                                 # Manage host upstreams
      vps upstream add HOST[:UPSTREAM] PATH        # Add upstream to host configuration
      vps upstream help [COMMAND]                  # Describe subcommands or one specific subcommand
      vps upstream list HOST                       # List upstreams of host configuration
      vps upstream remove HOST[:UPSTREAM]          # Remove upstream from host configuration

### Deploying a Plug / Phoenix / Rack / Rails application to a totally clean installed Ubuntu server

Let's say the SSH host is called `silver_surfer` and that the application is located at `~/Sources/spider_web`.

Just execute the following commands:

    $ vps init silver_surfer
    $ vps install silver_surfer docker
    $ vps upstream add silver_surfer ~/Sources/spider_web
    $ vps domain add silver_surfer:spider_web http://spider.web
    $ vps deploy silver_surfer

Et voilà. Your awesome website is online, powered by Docker and Nginx! :D

### Want to use a HTTPS domain?

No problem, just specify so and make sure you also pass a valid email address (which is recommended). During deployment `certbot` will be added to the docker compose config and the SSL certificates will be created using [`init-letsencrypt.sh`](https://github.com/archan937/vps/blob/master/templates/docker/init-letsencrypt.sh.erb).

    $ vps init silver_surfer
    $ vps install silver_surfer docker
    $ vps upstream add silver_surfer ~/Sources/spider_web
    $ vps domain add silver_surfer:spider_web https://spider.web your.valid@email-address.com
    $ vps deploy silver_surfer

Cool, huh? :D

### Want to add a (commonly used) service?

Easy. Just run `vps service add <yourhost>` (e.g. `vps service add silver_surfer`):



## Credits

Thanks Philipp Medien (@pentacent_hq) for writing about using Nginx and Let's Encrypt with Docker:

https://medium.com/@pentacent / [the-blog-post](https://medium.com/@pentacent/nginx-and-lets-encrypt-with-docker-in-less-than-5-minutes-b4b8a60d3a71)

Thanks Dmitry Fedosov (@dimafeng) for writing about scripting Docker based deployments:

http://dimafeng.com / [the-blog-post](http://dimafeng.com/2015/10/17/docker-distribution)

## TODO

* Add documentation about adding docker-compose and Nginx related configs plus adding pre- and postload tasks

## Contact me

For support, remarks and requests, please mail me at [pm_engel@icloud.com](mailto:pm_engel@icloud.com).

## License

Copyright (c) 2019 Paul Engel, released under the MIT license

http://github.com/archan937 – http://twitter.com/archan937 – pm_engel@icloud.com

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
