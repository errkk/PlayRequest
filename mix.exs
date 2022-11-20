defmodule PR.MixProject do
  use Mix.Project

  def project do
    [
      app: :pr,
      version: "0.1.0",
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      releases: releases()
    ]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [
      mod: {PR.Application, []},
      extra_applications: [:logger, :runtime_tools]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp deps do
    [
      {:ecto_sql, "~> 3.4"},
      {:postgrex, ">= 0.0.0"},
      {:phoenix_pubsub, "~> 2.0"},
      {:jason, "~> 1.0"},
      {:oauth2, "~> 2.0"},
      {:certifi, "~> 2.2"},
      {:telemetry_poller, "~> 0.4"},
      {:telemetry_metrics, "~> 0.4"},
      {:phoenix, "~> 1.7.0-rc.0", override: true},
      {:phoenix_live_view, "~> 0.18.3"},
      {:phoenix_live_dashboard, "~> 0.7.2"},
      {:phoenix_ecto, "~> 4.1"},
      {:phoenix_html, "~> 3.0"},
      {:phoenix_view, "~> 2.0"},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:gettext, "~> 0.11"},
      {:plug_cowboy, "~> 2.0"},
      {:ueberauth_google, "~> 0.8"},
      {:ex_machina, "~> 2.7", only: :test},
      {:timex, "~> 3.5"},
      {:logger_json, "~> 5.0"},
      {:esbuild, "~> 0.2", runtime: Mix.env() == :dev},
      {:logger_papertrail_backend, "~> 1.1"},
      {:dart_sass, "~> 0.4", runtime: Mix.env() == :dev},
      {:mix_test_watch, "~> 1.0", only: :dev, runtime: false},
      {:mock, "~> 0.3.6", only: :test},
      {:heroicons, "~> 0.5"}
    ]
  end

  defp releases() do
    [
      pr: [
        version: "0.0.1",
        include_executables_for: [:unix],
        applications: [pr: :permanent]
      ]
    ]
  end

  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate", "run priv/repo/seeds.exs"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"],
      "assets.deploy": [
        "esbuild default --minify",
        # No dart sass here cos its done in the docker file
        # as the dart-sass lib didn't run in fly's builder env
        "phx.digest"
      ]
    ]
  end
end
