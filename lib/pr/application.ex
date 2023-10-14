defmodule PR.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    Logger.add_backend(Sentry.LoggerBackend)

    topologies = Application.get_env(:libcluster, :topologies) || []

    children = [
      PR.Repo,
      PR.PlayState,
      PR.Ticker,
      PR.SonosAPI,
      PR.SpotifyAPI,
      PR.Telemetry,
      PRWeb.Endpoint,
      {Phoenix.PubSub, [name: PR.PubSub, adapter: Phoenix.PubSub.PG2]},
      {PR.Worker.GetInitialState, [nil]},
      PRWeb.Presence,
      {Cluster.Supervisor, [topologies, [name: PR.ClusterSupervisor]]}
    ]

    # This will only show up if log level is set <= :debug
    :ok =
      :telemetry.attach(
        "logger-json-ecto",
        [:pr, :repo, :query],
        &LoggerJSON.Ecto.telemetry_logging_handler/4,
        :debug
      )

    Supervisor.start_link(children, strategy: :one_for_one, name: PR.Supervisor)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    PRWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
