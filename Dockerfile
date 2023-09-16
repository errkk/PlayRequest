FROM elixir:1.14.3-alpine AS build
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

# Compile assets
# Install here and pass path to dart-sass config in config.exs
RUN npm install -g sass
COPY assets assets

# Build sass here, cos doing it via mix dun werk on fly
RUN cd assets && \
  sass --no-source-map --style=compressed css/app.scss ../priv/static/assets/app.css
RUN npm install
RUN mix assets.deploy

# compile project
COPY lib lib
RUN mix compile

# copy runtime configuration file
COPY config/releases.exs config/
COPY rel rel

# assemble release
RUN mix release

FROM alpine:3.17 AS app
RUN apk update \
  && apk add --virtual build-dependencies \
  build-base

# Get build arg to be in the env
ARG APP_REVISION
ENV APP_REVISION $APP_REVISION

# install runtime dependencies
RUN apk add --no-cache libstdc++ openssl ncurses-libs bash

ENV USER="elixir"
ENV LANG en_GB.UTF-8
ENV LANGUAGE en_GB:en
ENV LC_ALL en_GB.UTF-8
ENV ECTO_IPV6 true
ENV ERL_AFLAGS "-proto_dist inet6_tcp"

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

# Pretend this is in bash history
# It seems to be called .ash_history on alpine
RUN touch /home/elixir/.bash_history && \
  echo "/home/elixir/app/bin/pr remote" > /home/elixir/.ash_history

# copy release executables
COPY --from=build --chown="${USER}":"${USER}"\
  /app/_build/prod/rel/pr ./

COPY --chown="${USER}":"${USER}"\
  scripts/start.sh ./start.sh

CMD ["./start.sh"]
