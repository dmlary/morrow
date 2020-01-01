You will need to have both docker and docker compose installed.

## To build/rebuild the docker image:

Techincally the code is built into the image, however this is mostly for dependency installation and is immediately layered over with local files via docker compose.

```docker build -t morrow .```


## To run with Docker Compose:

This maps in the local directory in the right place and starts the server on port 1234

```docker-compose up```
