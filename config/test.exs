import Config

config :pr,
  allowed_user_domains: "example.com",
  sleep: 0

# Configure your database
config :pr, PR.Repo,
  username: "pr_user",
  password: "1234",
  database: "pr_test",
  hostname: System.get_env("POSTGRES_HOST") || "localhost",
  port: System.get_env("POSTGRES_PORT") || 5432,
  pool: Ecto.Adapters.SQL.Sandbox

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :pr, PRWeb.Endpoint,
  http: [port: 4002],
  server: false

config :logger, level: :warn
