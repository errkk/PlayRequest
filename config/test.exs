use Mix.Config

config :pr,
  allowed_user_domains: "example.com"

# Configure your database
config :pr, PR.Repo,
  username: "postgres",
  password: "postgres",
  database: "pr_test",
  hostname: System.get_env("POSTGRES_HOST") || "localhost",
  port: System.get_env("POSTGRES_PORT") || 5432,
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :pr_web, PRWeb.Endpoint,
  http: [port: 4002],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn
