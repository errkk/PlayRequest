defmodule PR.Worker.GetInitialState do
  use Task, restart: :temporary

  def start_link(arg) do
    Task.start_link(__MODULE__, :run, [arg])
  end

  def run(_arg) do
    PR.PlayState.get_initial_state()
  end
end
