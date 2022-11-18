defmodule PR.ReleaseTasks do
  @moduledoc false

  @repo_apps [
    :logger,
    :crypto,
    :ssl,
    :postgrex,
    :ecto_sql
  ]

  @repos Application.compile_env(:pr, :ecto_repos, [])

  require Logger

  def migrate(_argv \\ []) do
    start_services()
    run_migrations()
    stop_services()
  end

  def seed(_argv \\ []) do
    start_services()
    run_migrations()
    stop_services()
  end

  defp start_services do
    Logger.info("Starting dependencies..")
    # Start apps necessary for executing migrations

    Enum.each(@repo_apps, &Application.ensure_all_started/1)

    # Start the Repo(s) for app
    Logger.info("Starting repos..")
    :ok = Application.load(:pr)

    # Switch pool_size to 2 for ecto > 3.0
    Enum.each(@repos, & &1.start_link(pool_size: 2))
  end

  defp stop_services do
    Logger.info("Success!")
    :init.stop()
  end

  def run_migrations do
    Enum.each(@repos, &run_migrations_for/1)
  end

  defp run_migrations_for(repo) do
    app = Keyword.get(repo.config, :otp_app)
    Logger.info("Running migrations for #{app}")
    migrations_path = priv_path_for(repo, "migrations")
    Ecto.Migrator.run(repo, migrations_path, :up, all: true)
  end

  defp priv_path_for(repo, filename) do
    app = Keyword.get(repo.config, :otp_app)

    repo_underscore =
      repo
      |> Module.split()
      |> List.last()
      |> Macro.underscore()

    priv_dir = "#{:code.priv_dir(app)}"

    Path.join([priv_dir, repo_underscore, filename])
  end
end
