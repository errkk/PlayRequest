defmodule PR.Worker.GroupCheck do
  require Logger
  use GenServer

  alias PR.SonosHouseholds.GroupManager

  def start_link(default) when is_list(default) do
    GenServer.start_link(__MODULE__, default)
  end

  @impl true
  def init(state) do
    schedule_retry(0)
    {:ok, state}
  end

  @impl true
  def handle_info(:retry, [_, 0] = state) do
    Logger.info("GroupCheck retries exhausted")
    {:stop, :normal, state}
  end

  def handle_info(:retry, [group, retries] = state) do
    case GroupManager.check_or_recrate_active_group(group, retries) do
      :ok ->
        Logger.info("GroupCheck ok, no retry")
        {:stop, :normal, state}

      {:retry, group, retries} ->
        Logger.info("GroupCheck retry: #{retries}")

        get_wait()
        |> schedule_retry()

        {:noreply, [group, retries]}

      _ ->
        Logger.info("GroupCheck error, no retry")
        {:noreply, state}
    end
  end

  defp schedule_retry(wait) do
    Process.send_after(self(), :retry, wait)
  end

  defp get_wait() do
    Application.get_env(:pr, :sleep)
  end
end
