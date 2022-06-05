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
    Agent.start_link(fn -> %{play_state: %{}, metadata: %{}, progress: nil, error_mode: nil} end, name: __MODULE__)
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
        Logger.warn("PlayState could not fetch initial state")
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
  def handle_play_state_webhook(data, group_id, request_id) do
    case SonosHouseholds.get_active_group() do
      %Group{group_id: ^group_id} ->
        Logger.metadata(group_id: group_id, request_id: request_id, error_mode: get(:error_mode))
        Logger.info("Handling PlayState")
      data
      |> SonosAPI.convert_result()
      |> process_play_state()
      _ -> 
        Logger.metadata(group_id: group_id)
        Logger.warn("Skipping PlayState, unrecongnised group: #{group_id}")
    end
  end

  @doc "Called by webhook"
  def handle_metadata_webhook(data, group_id, request_id) do
    case SonosHouseholds.get_active_group() do
      %Group{group_id: ^group_id} ->
        Logger.metadata(group_id: group_id, request_id: request_id, error_mode: get(:error_mode))
        Logger.info("Handling Metadata")
        data
        |> SonosAPI.convert_result()
        |> process_metadata()
      _ -> 
        Logger.metadata(group_id: group_id)
        Logger.warn("Skipping Metadata unrecongnised group_id: #{group_id}")
    end
  end

  def handle_error_webhook(data, group_id, request_id) do
    case SonosHouseholds.get_active_group() do
      %Group{group_id: ^group_id} ->
        Logger.metadata(group_id: group_id, request_id: request_id, error_mode: get(:error_mode))
        Logger.error("Handling Error webhook", error: Jason.encode!(data))
        data
        |> SonosAPI.convert_result()
        |> process_sonos_error()
      _ -> 
        Logger.metadata(group_id: group_id)
        Logger.warn("Skipping Error webhook unrecongnised group_id: #{group_id}")
    end
  end

  def is_idle? do
    match?(%PlaybackState{state: :idle}, get(:play_state))
  end

  defp watch_play_state(%{state: :idle} = state) do
    # This is from play state. When player goes idle after playing everything.
    # Metadata will come soon, and wont match anything in the queue.
    # If that's updated the queue, then we can check for new tracks and re-trigger
    # with the new tracks.

    # TODO might be worth checking metadata here
    case Queue.has_unplayed() do
      num when num > 0 ->
        Logger.info("Player IDLE. But, queue has more tracks. Loading them in 1000ms")
        Process.sleep(1000)
        trigger_on_sonos_system()
        state

      _ ->
        Logger.info("Player idle, Queue empty.")
        state
    end
  end

  # If it's managed to play, maybe the error is over?
  defp watch_play_state(%{state: :playing} = state) do
    if get(:error_mode) do
        Logger.metadata(error_mode: nil)
        Logger.info("Clearing error mode")
        # Update agent
        update_state(nil, :error_mode)
        # Update live view 
        broadcast(nil, :sonos_error)
        # Ok, everybody just calm down, what are we actually playing now?
        Logger.info("Refetching metadata after error mode")
        # Wonder if this sort of thing should be async, as it's in a webhook event
        SonosAPI.get_metadata()
        |> process_metadata()

        state
      else
        state 
    end
  end

  defp watch_play_state(d), do: d

  defp trigger_on_sonos_system do
    case get(:play_state) do
      %PlaybackState{state: :idle} ->
        Logger.info("Still idle, triggering")
        Music.trigger_playlist()

      %PlaybackState{state: state} ->
        Logger.warn("Cancelled trigger, state is now: #{state}")
    end
  end

  def process_metadata(data) do
   case cast_metadata(data) do
     {:ok, metadata} ->
        metadata
        |> update_playing()
        |> update_state(:metadata)
        |> broadcast(:metadata)

        Music.queue_updated()

        metadata
      _ ->
        Logger.info("not processing metadata")
        data
      end
  end

  def process_play_state(data) do
    data
    |> PlaybackState.new()
    |> update_state(:play_state)
    |> broadcast(:play_state)
    |> tap(fn %{state: state} -> Logger.metadata(playback_state: state) end)
    |> watch_play_state()
  end

  def process_sonos_error(data) do
    broadcast(data, :sonos_error)

    # Set a flag on the agent, un set it when play state gets back to playing
    update_state(true, :error_mode)
    :ok
  end

  defp update_playing(%{current_item: %{name: name} = current} = state) do
    Logger.metadata(playback_state: Map.get(get(:play_state), :state))
    if get(:error_mode) do
      Logger.warn("Update playing: Cancelled, cos error mode")
      state
    else
      case Queue.set_current(current) do
        {:ok, [playing: 1]} ->
          Logger.info("Started playing queued track: #{name}")
          state

        {:ok, [playing: nil]} ->
          Logger.debug("Already playing: #{name} (or is it nothing?)")
          state

        _ ->
          Logger.debug("Not in the queue: #{name}. Ignoring")
          state
      end
    end
  end

  defp update_playing(%{current_item: %{}} = state) do
    Queue.set_current(%{})
    Logger.info("Nothing playing on the Sonos")
    state
  end

  # Called on an interval by supervisor
  def tick do
    with %{
           current_item: %SonosItem{duration: duration}
         } <- get(:metadata),
         %{playing_since: %DateTime{} = playing_since} <- Queue.get_playing(),
         diff <- DateTime.diff(DateTime.utc_now(), playing_since, :millisecond),
         true <- Kernel.>(duration, diff) do
      diff
      |> update_state(:progress)
      |> broadcast(:progress)
    else
      _ -> nil
    end
  end

  defp cast_metadata(%{container: %{type: "playlist"}, current_item: current_item}) do
    try do
      sonos_item = SonosItem.new(current_item)
      data = %{current_item: sonos_item}

      {:ok, data}
    rescue
      _ ->
        Logger.warn("Error casting metadata")
        {:ok, %{current_item: %{}}}
    end
  end

  defp cast_metadata(_) do
    Logger.info("probably playing something else")
    {:error, :probably_playing_something_else}
  end
end
