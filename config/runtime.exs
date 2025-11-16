import Config

# config/runtime.exs is executed for all environments, including
# during releases. It is executed after compilation and before the
# system starts, so it is typically used to load production configuration
# and secrets from environment variables or elsewhere. Do not define
# any compile-time configuration in here, as it won't be applied.

# ## Using releases
#
# If you use `mix release`, you need to explicitly enable the server
# by passing the PHX_SERVER=true when you start it:
#
#     PHX_SERVER=true bin/pr start
#
# Alternatively, you can use `mix phx.gen.release` to generate a `bin/server`
# script that automatically sets the env var above.
if System.get_env("PHX_SERVER") do
  config :pr, PRWeb.Endpoint, server: true
end

# Common runtime configuration for all environments
config :pr, :sonos,
  scopes: "playback-control-all",
  redirect_uri: "#{System.get_env("REDIRECT_URL_BASE")}/sonos/authorized",
  key: System.get_env("SONOS_KEY"),
  secret: System.get_env("SONOS_SECRET")

config :pr, :spotify,
  scopes:
    ~w(user-modify-playback-state user-read-currently-playing user-read-playback-state playlist-modify-private playlist-read-private),
  redirect_uri: "#{System.get_env("REDIRECT_URL_BASE")}/spotify/authorized",
  user_id: System.get_env("SPOTIFY_USER_ID"),
  key: System.get_env("SPOTIFY_CLIENT_ID"),
  secret: System.get_env("SPOTIFY_SECRET")

config :ueberauth, Ueberauth.Strategy.Google.OAuth,
  client_id: System.get_env("GOOGLE_CLIENT_ID"),
  client_secret: System.get_env("GOOGLE_CLIENT_SECRET")

config :pr,
  allowed_user_domains: System.get_env("ALLOWED_USER_DOMAINS"),
  installation_name: System.get_env("INSTALLATION_NAME", "PlayRequest"),
  super_likes_allowed: System.get_env("SUPER_LIKES_ALLOWED", "2"),
  burns_allowed: System.get_env("BURNS_ALLOWED", "2")

config :pr, :feature_flags,
  show_volume: System.get_env("FF_VOLUME", ""),
  show_toggle_playback: System.get_env("FF_TOGGLE_PLAYBACK", ""),
  show_skip: System.get_env("FF_SKIP", ""),
  scale_play_button: System.get_env("FF_SCALE_PLAY_BUTTON", ""),
  show_super_like: System.get_env("FF_SUPER_LIKE", ""),
  show_burn: System.get_env("FF_BURN", "")

config :sentry,
  dsn: System.get_env("SENTRY_DSN"),
  enable_source_code_context: true,
  root_source_code_path: File.cwd!()

# Production-specific configuration
if config_env() == :prod do
  config :logger,
    backends: [LoggerJSON],
    level: :info

  config :pr, PR.Repo,
    url: System.get_env("DATABASE_URL") || raise("DATABASE_URL not available"),
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    ssl: false,
    socket_options: [:inet6]

  config :pr, PRWeb.Endpoint,
    http: [port: String.to_integer(System.get_env("PORT") || "4000")],
    url: [host: System.get_env("HOSTNAME"), port: 443, scheme: "https"],
    cache_static_manifest: "priv/static/cache_manifest.json",
    force_ssl: [rewrite_on: [:x_forwarded_proto]],
    server: true

  # Production requires these environment variables
  unless System.get_env("SONOS_KEY"), do: raise("SONOS_KEY not available")
  unless System.get_env("SONOS_SECRET"), do: raise("SONOS_SECRET not available")
  unless System.get_env("SPOTIFY_USER_ID"), do: raise("SPOTIFY_USER_ID not available")
  unless System.get_env("SPOTIFY_CLIENT_ID"), do: raise("SPOTIFY_CLIENT_ID not available")
  unless System.get_env("SPOTIFY_SECRET"), do: raise("SPOTIFY_SECRET not available")
  unless System.get_env("GOOGLE_CLIENT_ID"), do: raise("GOOGLE_CLIENT_ID not available")
  unless System.get_env("GOOGLE_CLIENT_SECRET"), do: raise("GOOGLE_CLIENT_SECRET not available")

  config :pr,
    sleep: 60_000

  app_name =
    System.get_env("FLY_APP_NAME") ||
      raise "FLY_APP_NAME not available"

  config :libcluster,
    debug: true,
    topologies: [
      fly6pn: [
        strategy: Cluster.Strategy.DNSPoll,
        config: [
          polling_interval: 5_000,
          query: "#{app_name}.internal",
          node_basename: app_name
        ]
      ]
    ]

  config :sentry,
    tags: %{
      env: System.get_env("RELEASE_STAGE") || "dev"
    },
    environment_name: System.get_env("RELEASE_STAGE") || :prod,
    release: System.get_env("APP_REVISION", "dev")
end

# Development-specific configuration
if config_env() == :dev do
  config :sentry,
    environment_name: :dev,
    tags: %{
      env: "dev"
    }
end
