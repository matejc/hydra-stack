Hydra Stack
===========

Hydra inside docker
- with extra builders for distributed builds (up to 10)
- with statsd and graphite

This is work in progress, usable, but I wouldn't use it in production :)

To use it you need Docker and docker-compose.
Do change passwords before first run inside docker-compose.yml
Run it like every other docker compose project:

```
$ docker-compose build
$ docker-compose up
```

You can add builders by adding to docker-compose.yml something like that,
but the name must start with `builderN` where N is a number from 1 to 10,
I am brute forcing those hostnames and adding them to /etc/nix/machines if they
have open 22 port:

```
builder5:
    build: builder
    volumes_from:
        - data:ro
    volumes:
        - /var/volumes/hydra/nix5:/nix
```

And do not forget to link them to `hydra-app`.


Known problems:
- inside containers, hydra components are not respecting /etc/hosts file, but ping works
