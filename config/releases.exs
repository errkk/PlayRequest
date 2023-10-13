import Config

config :pr, PR.Repo,
  url: System.get_env("DATABASE_URL"),
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

config :pr, PRWeb.Endpoint,
  http: [port: System.get_env("PORT")],
  url: [host: System.get_env("HOSTNAME"), port: 443, scheme: "https"],
  cache_static_manifest: "priv/static/cache_manifest.json"

config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id, :playback_state, :error_mode]

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
  allowed_user_domains: System.get_env("ALLOWED_USER_DOMAINS", ""),
  installation_name: System.get_env("INSTALLATION_NAME", "PlayRequest"),
  super_likes_allowed: System.get_env("SUPER_LIKES_ALLOWED", "2")

config :pr, :feature_flags,
  show_volume: System.get_env("FF_VOLUME", ""),
  show_toggle_playback: System.get_env("FF_TOGGLE_PLAYBACK", ""),
  show_skip: System.get_env("FF_SKIP", ""),
  scale_play_button: System.get_env("FF_SCALE_PLAY_BUTTON", ""),
  show_super_like: System.get_env("FF_SUPER_LIKE", "")

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
  dsn: System.get_env("SENTRY_DSN"),
  tags: %{
    env: System.get_env("RELEASE_STAGE") || "dev"
  },
  environment_name: System.get_env("RELEASE_STAGE") || "dev",
  included_environments: [:staging, :prod]
