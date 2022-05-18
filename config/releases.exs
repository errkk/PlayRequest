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
  metadata: [:request_id, :playback_state]

config :logger, :logger_papertrail_backend,
  host: System.get_env("PAPERTRAIL_HOST"),
  level: :info,
  system_name: System.get_env("HOSTNAME"),
  metadata_filter: [],
  format: "$metadata $message",
  metadata: [:request_id, :playback_state]

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
  installation_name: System.get_env("INSTALLATION_NAME", "PlayRequest")
