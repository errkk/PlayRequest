# This file is responsible for configuring your umbrella
# and **all applications** and their dependencies with the
# help of Mix.Config.
#
# Note that all applications in your umbrella share the
# same configuration and dependencies, which is why they
# all use the same configuration file. If you want different
# configurations or dependencies per app, it is best to
# move said applications out of the umbrella.
import Config

# Configure Mix tasks and generators
config :pr,
  ecto_repos: [PR.Repo],
  playlist_name: "PlayRequest",
  timezone: "Europe/London"

# Configures the endpoint
config :pr, PRWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "MBQFquRClfM/IuOPei8yy0dwxawJRGOnuEH4zbPsKx7+PPc3UWVYJqKufr76yDbe",
  render_errors: [view: PRWeb.ErrorView, accepts: ~w(html json)],
  pubsub_server: PR.PubSub,
  live_view: [
    signing_salt: "SECRET_SALT"
  ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

config :ueberauth, Ueberauth,
  providers: [
    google: {Ueberauth.Strategy.Google, [default_scope: "email profile"]}
  ]

config :esbuild,
  version: "0.12.18",
  default: [
    args: ~w(js/app.js js/worker.js --bundle --target=es2016 --outdir=../priv/static/assets),
    cd: Path.expand("../assets", __DIR__),
    env: %{"NODE_PATH" => Path.expand("../deps", __DIR__)}
  ]

config :dart_sass,
  version: "1.49.0",
  default: [
    args: ~w(css/app.scss ../priv/static/assets/app.css),
    cd: Path.expand("../assets", __DIR__)
  ]

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
