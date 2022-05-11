import Config

config :logger, level: :info

config :pr, PR.Repo, ssl: false, socket_options: [:inet6]

config :pr, PRWeb.Endpoint,
  force_ssl: [rewrite_on: [:x_forwarded_proto]],
  server: true,
  root: ".",
  version: Application.spec(:pr, :vsn)
