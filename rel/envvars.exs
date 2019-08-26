import Config

config :lv, :sonos,
  key: System.get_env("SONOS_KEY"),
  secret: System.get_env("SONOS_SECRET")

config :lv, :spotify,
  user_id: System.get_env("SPOTIFY_USER_ID"),
  key: System.get_env("SPOTIFY_CLIENT_ID"),
  secret: System.get_env("SPOTIFY_SECRET")
