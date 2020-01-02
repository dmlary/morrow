# morrow-mud

## Docker
You will need to have both docker and docker compose installed.

## To build/rebuild the docker image:

Techincally the code is built into the image, however this is mostly for dependency installation and is immediately layered over with local files via docker compose.

You should really only have to run this if you change versions or update dependencies.

```docker build -t morrow .```


## To run with Docker Compose:

This maps in the local directory in the right place and starts the server on port 1234

```docker-compose up```

## Project setup
```
npm install
```

### Compiles and hot-reloads for development
```
npm run serve
```

### Compiles and minifies for production
```
npm run build
```

### Lints and fixes files
```
npm run lint
```

### Customize configuration
See [Configuration Reference](https://cli.vuejs.org/config/).
