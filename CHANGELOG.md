## VPS CHANGELOG

### Version 0.2.2 (January 2, 2020)

* Automatically add container names for upstreams and services
* Add opportunity to add lines to the generated Dockerfile

### Version 0.2.1 (January 2, 2020)

* Support NodeJS based applications
* Clean up default upstream specs
* Set container name when adding upstream

### Version 0.2.0 (December 31, 2019)

* Provide ability to add both custom HTTP and HTTPS Nginx configs

### Version 0.1.2 (September 29, 2019)

* Run postload tasks at the end of deployment
* Fix generating Rails and Rack Dockerfile (installing the correct Bundler version)
* Include configured :services in the generated docker-compose.yml file

### Version 0.1.1 (August 12, 2019)

* Initial release
