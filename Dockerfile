FROM elixir:1.12-alpine AS build
RUN apk update \
    && apk add --virtual build-dependencies \
        build-base
RUN apk add bash nodejs npm inotify-tools openssl

WORKDIR /app

RUN mix local.hex --force \
  && mix local.rebar --force

ENV MIX_ENV="prod"

# install mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only prod

# compile dependencies
RUN mix deps.compile

# copy compile configuration files
RUN mkdir config
COPY config/config.exs config/prod.exs config/

# copy assets
COPY priv priv
COPY assets assets

# Compile assets
# RUN mix assets.deploy

# compile project
COPY lib lib
RUN mix compile

# copy runtime configuration file
COPY config/releases.exs config/

# assemble release
RUN mix release

FROM alpine:3.12 AS app
RUN apk update \
    && apk add --virtual build-dependencies \
        build-base

# install runtime dependencies
RUN apk add --no-cache libstdc++ openssl ncurses-libs bash

ENV USER="elixir"
ENV LANG en_GB.UTF-8
ENV LANGUAGE en_GB:en
ENV LC_ALL en_GB.UTF-8

WORKDIR "/home/${USER}/app"
RUN mkdir "/home/${USER}/app/tmp"

# Create  unprivileged user to run the release
RUN \
  addgroup \
   -g 1000 \
   -S "${USER}" \
  && adduser \
   -s /bin/sh \
   -u 1000 \
   -G "${USER}" \
   -h "/home/${USER}" \
   -D "${USER}" \
  && su "${USER}"

RUN chown ${USER}:${USER} "/home/${USER}/app/tmp"

# run as user
USER "${USER}"

# copy release executables
COPY --from=build --chown="${USER}":"${USER}"\
  /app/_build/prod/rel/pr ./

# Copy util scripts
COPY --chown="${USER}":"${USER}" ./scripts/start.sh ./start.sh
COPY --chown="${USER}":"${USER}" ./scripts/migrate.sh ./migrate.sh
COPY --chown="${USER}":"${USER}" ./scripts/remote.sh ./remote.sh

# Runs from release bin
# ENTRYPOINT ["bin/pr"]
# CMD ["start"]
 CMD ["./start.sh"]
