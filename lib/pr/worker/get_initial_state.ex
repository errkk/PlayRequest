defmodule PR.Worker.GetInitialState do
  use Task, restart: :temporary

  def start_link(arg) do
    Task.start_link(__MODULE__, :run, [arg])
  end

  def run(_arg) do
    case env() do
      :test ->
        :ok

      _ ->
        PR.PlayState.get_initial_state()
        PR.SonosAPI.subscribe_webhooks()
    end
  end

  def env do
    Application.get_env(:pr, :env)
  end
end
