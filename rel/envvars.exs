import Config

config :lv, :sonos,
  key: System.get_env("SONOS_KEY"),
  secret: System.get_env("SONOS_SECRET")

config :spotify_ex,
  user_id: System.get_env("SPOTIFY_USER_ID"),
  client_id: System.get_env("SPOTIFY_CLIENT_ID"),
  secret_key: System.get_env("SPOTIFY_SECRET")
