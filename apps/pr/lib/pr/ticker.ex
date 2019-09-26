defmodule PR.Ticker do
  use GenServer
  alias PR.PlayState

  def start_link(default) when is_list(default) do
    GenServer.start_link(__MODULE__, default)
  end

  @impl true
  def init(state) do
    schedule_tick
    {:ok, state}
  end

  @impl true
  def handle_info(:tick, state) do
    schedule_tick
    PlayState.tick()
    {:noreply, state}
  end

  defp schedule_tick do
    Process.send_after(self(), :tick, 1000)
  end
end
