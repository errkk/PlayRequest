import Config

config :pr, PR.Repo,
  ssl: true,
  url: System.get_env("DATABASE_URL"),
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

config :pr_web, PRWeb.Endpoint,
  server: true,
  url: [scheme: "https", host: System.get_env("HOSTNAME"), port: String.to_integer(System.get_env("PORT"))],
  force_ssl: [rewrite_on: [:x_forwarded_proto]],
  cache_static_manifest: "priv/static/cache_manifest.json"

import_config "../../envvars.exs"
