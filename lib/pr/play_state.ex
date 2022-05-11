defmodule PR.PlayState do
  @moduledoc false

  require Logger
  use Agent
  alias PR.SonosAPI
  alias PR.Music
  alias PR.Music.{SonosItem, PlaybackState}
  alias PR.Queue
  alias PR.SonosHouseholds
  alias PR.SonosHouseholds.{GroupManager, Group}

  @topic inspect(__MODULE__)

  def start_link(_) do
    Agent.start_link(fn -> %{play_state: %{}, metadata: %{}, progress: nil} end, name: __MODULE__)
  end

  def get_initial_state() do
    GroupManager.check_groups()

    try do
      Logger.info("Fetching inital state")

      SonosAPI.get_playback()
      |> process_play_state()

      SonosAPI.get_metadata()
      |> process_metadata()
    rescue
      _err ->
        Logger.error("PlayState could not fetch initial state")
    end
  end

  def get(key) do
    Agent.get(__MODULE__, fn state ->
      Map.get(state, key)
    end)
  end

  def debug_toggle_playing() do
    case get(:play_state) do
      %PlaybackState{state: :playing} ->
        %PlaybackState{state: :paused}

      %PlaybackState{state: :paused} ->
        %PlaybackState{state: :playing}
    end
    |> update_state(:play_state)
    |> broadcast(:play_state)
  end

  defp update_state(data, key) do
    Agent.update(__MODULE__, fn state ->
      Map.put(state, key, data)
    end)

    data
  end

  @spec broadcast(any(), atom()) :: no_return()
  defp broadcast(data, key) do
    Phoenix.PubSub.broadcast(PR.PubSub, @topic, {__MODULE__, data, key})
    data
  end

  # API functions

  @doc "Use in the live view to receive updates"
  def subscribe do
    Phoenix.PubSub.subscribe(PR.PubSub, @topic)
  end

  @doc "Update the state from the webhook controller"
  def handle_play_state_webhook(data, group_id) do
    case SonosHouseholds.get_active_group() do
      %Group{group_id: ^group_id} ->
        Logger.info("Handling PlayState for #{group_id}")
      data
      |> SonosAPI.convert_result()
      |> process_play_state()
      _ -> 
        Logger.info("Skipping PlayState for #{group_id}")
    end
  end

  @doc "Called by webhook"
  def handle_metadata_webhook(data, group_id) do
    case SonosHouseholds.get_active_group() do
      %Group{group_id: ^group_id} ->
        Logger.info("Handling Metadata for #{group_id}")
        data
        |> SonosAPI.convert_result()
        |> process_metadata()
      _ -> 
        Logger.info("Skipping Metadata for #{group_id}")
    end
  end

  def is_idle? do
    match?(%PlaybackState{state: :idle}, get(:play_state))
  end

  defp watch_play_state(%{state: :idle}) do
    # This is from play state. When player goes idle after playing everything.
    # Metadata will come soon, and wont match anything in the queue.
    # If that's updated the queue, then we can check for new tracks and re-trigger
    # with the new tracks.
    case Queue.has_unplayed() do
      num when num > 0 ->
        Logger.info("Player IDLE. But, queue has more tracks. Loading them in 1000ms")
        Process.sleep(1000)
        Music.bump_and_reload()

      _ ->
        Logger.info("Player idle, Queue empty.")
        nil
    end
  end

  defp watch_play_state(d), do: d

  defp process_metadata(data) do
    data
    |> cast_metadata()
    |> update_playing()
    |> update_state(:metadata)
    |> broadcast(:metadata)

    Music.queue_updated()

    data
  end

  defp process_play_state(data) do
    data
    |> PlaybackState.new()
    |> update_state(:play_state)
    |> broadcast(:play_state)
    |> watch_play_state()
  end

  defp update_playing(%{current_item: %{name: name} = current} = state) do
    case Queue.set_current(current) do
      {:started, playing_since} ->
        Logger.info("Started playing queued track: #{name}")
        Map.put(state, :playing_since, playing_since)

      {:already_started, playing_since} ->
        Logger.info("Already playing: #{name}")
        Map.put(state, :playing_since, playing_since)

      _ ->
        Logger.info("Not in the queue: #{name}. Ignoring")
        state
    end
  end

  # Called on an interval by supervisor
  def tick do
    with %{
           playing_since: %DateTime{} = playing_since,
           current_item: %SonosItem{duration: duration}
         } <- get(:metadata),
         diff <- DateTime.diff(DateTime.utc_now(), playing_since, :millisecond),
         true <- Kernel.>(duration, diff) do
      diff
      |> update_state(:progress)
      |> broadcast(:progress)
    else
      _ -> nil
    end
  end

  defp cast_metadata(%{} = data) do
    try do
      data
      |> Map.update(:current_item, %{}, &SonosItem.new/1)
      |> Map.update(:next_item, %{}, &SonosItem.new/1)
      |> Map.delete(:container)
      # TODO ensure container is playrequest
      # maybe get rid of next item
    rescue
      _ ->
        %{current_item: %{}, next_item: %{}}
    end
  end
end
