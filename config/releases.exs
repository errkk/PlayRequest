import Config

config :pr, PR.Repo,
  ssl: true,
  url: System.get_env("DATABASE_URL"),
  pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")

config :pr_web, PRWeb.Endpoint,
  server: true,
  url: [scheme: "http", host: "0.0.0.0", port: String.to_integer(System.get_env("PORT"))]

import_config "../../envvars.exs"
