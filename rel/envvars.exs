import Config

config :pr, :sonos,
  key: System.get_env("SONOS_KEY"),
  secret: System.get_env("SONOS_SECRET")

config :pr, :spotify,
  user_id: System.get_env("SPOTIFY_USER_ID"),
  key: System.get_env("SPOTIFY_CLIENT_ID"),
  secret: System.get_env("SPOTIFY_SECRET")

config :pr, PR.Repo,
  ssl: true,
  url: System.get_env("DATABASE_URL"),
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")
