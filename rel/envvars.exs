import Config

config :pr, :sonos,
  scopes: "playback-control-all",
  redirect_uri: "#{System.get_env("REDIRECT_URL_BASE")}/sonos/authorized",
  key: System.get_env("SONOS_KEY"),
  secret: System.get_env("SONOS_SECRET")

config :pr, :spotify,
  scopes: ~w(user-modify-playback-state user-read-currently-playing user-read-playback-state playlist-modify-private playlist-read-private),
  redirect_uri: "#{System.get_env("REDIRECT_URL_BASE")}/spotify/authorized",
  user_id: System.get_env("SPOTIFY_USER_ID"),
  key: System.get_env("SPOTIFY_CLIENT_ID"),
  secret: System.get_env("SPOTIFY_SECRET")

config :ueberauth, Ueberauth.Strategy.Google.OAuth,
  client_id: System.get_env("GOOGLE_CLIENT_ID"),
  client_secret: System.get_env("GOOGLE_CLIENT_SECRET")

config :pr,
  allowed_user_domains: System.get_env("ALLOWED_USER_DOMAINS"),
  installation_name: System.get_env("INSTALLATION_NAME")
