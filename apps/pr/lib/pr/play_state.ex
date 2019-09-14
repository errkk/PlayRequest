defmodule PR.PlayState do
  @moduledoc false

  require Logger
  use Agent
  alias PR.SonosAPI
  alias PR.Music
  alias PR.Music.{SonosItem, PlaybackState}
  alias PR.Queue

  @topic inspect(__MODULE__)

  def start_link(_) do
    Agent.start_link(fn -> %{play_state: %{}, metadata: %{}} end, name: __MODULE__)
  end

  def get_initial_state() do
    try do
      Logger.info "Fetching inital state"
      SonosAPI.get_playback()
      |> process_play_state()
      SonosAPI.get_metadata()
      |> process_metadata()
    rescue
      _ ->
      Logger.error "PlayState could not fetch initial state"
    end
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

  @spec broadcast(any(), :atom) :: no_return()
  defp broadcast(data, key) do
    Phoenix.PubSub.broadcast(PRWeb.PubSub, @topic, {__MODULE__, data, key})
    data
  end

  # API functions

  @doc "Use in the live view to receive updates"
  def subscribe do
    Phoenix.PubSub.subscribe(PRWeb.PubSub, @topic)
  end

  @doc "Update the state from the webhook controller"
  def handle_play_state_webhook(data) do
    data
    |> SonosAPI.convert_result()
    |> process_play_state()
  end

  @doc "Called by webhook"
  def handle_metadata_webhook(data) do
    data
    |> SonosAPI.convert_result()
    |> process_metadata()
  end

  defp watch_metadata(%{current_item: %SonosItem{}, next_item: %{}}) do
    # Metadta tells us there's nothing up next
    case Queue.has_unplayed do
      num when num > 0 ->
        Logger.info "Sonos queus missing tracks. re-triggering"
        Music.load_playlist()
      _ ->
        nil
    end

  end

  defp process_metadata(data) do
    data
    |> cast_metadata()
    |> update_playing()
    |> update_state(:metadata)
    |> broadcast(:metadata)
    |> watch_metadata()
  end

  defp process_play_state(data) do
    data
    |> PlaybackState.new()
    |> update_state(:play_state)
    |> broadcast(:play_state)
  end

  defp update_playing(%{current_item: current} = state) do
    Queue.set_current(current)
    state
  end

  defp cast_metadata(%{} = data) do
    try do
      data
      |> Map.update(:current_item, %{}, &SonosItem.new/1)
      |> Map.update(:next_item, %{}, &SonosItem.new/1)
      |> Map.delete(:container)
    rescue
      _ ->
      %{current_item: %{}, next_item: %{}}
    end
  end
end

