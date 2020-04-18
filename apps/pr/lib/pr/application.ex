defmodule PR.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application
  import Supervisor.Spec

  def start(_type, _args) do
    children = [
      PR.Repo,
      PR.PlayState,
      PR.Ticker,
      PR.SonosAPI,
      PR.SpotifyAPI,
      PR.Telemetry,
      worker(Task, [&PR.PlayState.get_initial_state/0], restart: :temporary),
    ]

    Supervisor.start_link(children, strategy: :one_for_one, name: PR.Supervisor)
  end
end
