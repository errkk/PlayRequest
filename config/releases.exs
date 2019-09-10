import Config

config :pr, PR.Repo,
  ssl: true,
  url: System.get_env("DATABASE_URL"),
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

config :pr_web, PRWeb.Endpoint,
  server: true,
  http: [port: System.get_env("PORT")],
  url: [scheme: "http", host: System.get_env("HOSTNAME"), port: 80],
  force_ssl: [rewrite_on: [:x_forwarded_proto]],
  root: ".",
  version: Application.spec(:pr_web, :vsn)
  cache_static_manifest: "priv/static/cache_manifest.json"

config :logger, level: :info

import_config "../../envvars.exs"
