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
  namespace: PR,
  ecto_repos: [PR.Repo],
  playlist_name: "PlayRequestDev"

config :pr_web,
  namespace: PRWeb,
  ecto_repos: [PR.Repo],
  generators: [context_app: :pr]

# Configures the endpoint
config :pr_web, PRWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "MBQFquRClfM/IuOPei8yy0dwxawJRGOnuEH4zbPsKx7+PPc3UWVYJqKufr76yDbe",
  render_errors: [view: PRWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: PRWeb.PubSub, adapter: Phoenix.PubSub.PG2],
  live_view: [
     signing_salt: "SECRET_SALT"
   ]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
case Mix.env() do
  :dev ->
    import_config "#{Mix.env()}.exs"
  _ -> nil
end

# Load env vars
import_config "../rel/envvars.exs"

