# morrow-mud

## Requirements
* ruby 2.6
* bundler gem
* npm

## Intstall
```
bundle install
npm install
```

## Development
To start the server in development mode:

```
rake start-dev
```

This will:
* start the mud engine
* start the telnet server (port 1234)
* start the web server (port 8080)
* monitor the web-assets for changes, and rebuild them as they're modified

### Other helpful rake tasks
To attach the debugger to the server, `rake pry`.

## Docker
You will need to have both docker and docker compose installed.

## To build/rebuild the docker image:

Techincally the code is built into the image, however this is mostly for dependency installation and is immediately layered over with local files via docker compose.

You should really only have to run this if you change versions or update dependencies.

```docker build -t morrow .```


## To run with Docker Compose:

This maps in the local directory in the right place and starts the server on port 1234

```docker-compose up```
