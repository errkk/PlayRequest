defmodule E.PlayState do
  @moduledoc false

  require Logger
  use Agent
  alias E.SonosAPI

  @topic inspect(__MODULE__)

  def start_link(_) do
    Agent.start_link(fn -> %{play_state: %{}, metadata: %{}} end, name: __MODULE__)
  end

  def get_initial_state() do
    Logger.info "Fetching inital state"
    SonosAPI.get_playback()
    |> update_state(:play_state)
    SonosAPI.get_metadata()
    |> update_state(:metadata)
  end

  def get(key) do
    Agent.get __MODULE__, fn state ->
      Map.get(state, key)
    end
  end

  defp update_state(data, key) do
    Agent.update __MODULE__, fn state ->
      Map.put(state, key, data)
    end
    data
  end

  defp broadcast(data, key) do
    Phoenix.PubSub.broadcast(EWeb.PubSub, @topic, {__MODULE__, data, key})
  end

  # API functions

  @doc "Use in the live view to receive updates"
  def subscribe do
    Phoenix.PubSub.subscribe(EWeb.PubSub, @topic)
  end

  @doc "Update the state from the webhook controller"
  def handle_playstate(data) do
    data
    |> SonosAPI.convert_result()
    |> update_state(:play_state)
    |> broadcast(:play_state)
  end

  def handle_metadata(data) do
    data
    |> SonosAPI.convert_result()
    |> update_state(:metadata)
    |> broadcast(:metadata)
  end

end

