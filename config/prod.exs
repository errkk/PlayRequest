import Config

config :logger,
  backends: [LoggerJSON],
  level: :info

config :pr, PR.Repo, ssl: false, socket_options: [:inet6]

config :pr, PRWeb.Endpoint,
  force_ssl: [rewrite_on: [:x_forwarded_proto]],
  server: true,
  root: ".",
  version: Application.spec(:pr, :vsn)

config :pr,
  sleep: 60_000

config :sentry,
  enable_source_code_context: true,
  root_source_code_path: File.cwd!()
