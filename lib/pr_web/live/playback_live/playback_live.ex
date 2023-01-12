defmodule PRWeb.PlaybackLive do
  require Logger
  use Phoenix.HTML
  use PRWeb, :live_view
  use PRWeb, :helpers

  alias PR.{Music, PlayState}
  alias PR.Music.{SonosItem, PlaybackState}
  alias PR.Auth
  alias PR.Auth.User
  alias PR.Scoring
  alias PR.Scoring.Point
  alias PR.Queue.Track
  alias PR.Queue

  import PRWeb.PlaybackComponents
  import PRWeb.TrackComponent

  embed_templates "*"

  @impl true
  def mount(_params, %{"user_id" => user_id}, socket) do
    if connected?(socket), do: PlayState.subscribe()
    if connected?(socket), do: Music.subscribe()
    play_state = PlayState.get(:play_state)
    metadata = PlayState.get(:metadata)
    progress = PlayState.get(:position)

    socket =
      assign(
        socket,
        metadata: metadata,
        play_state: play_state,
        progress: progress,
        result: [],
        q: nil,
        loading: nil,
        recently_liked: nil,
        participated: Queue.has_participated?(%User{id: user_id}),
        playlist: Music.get_playlist(%User{id: user_id}),
        page_title: page_title(metadata),
        show_encouraging_message: show_encouraging_message(user_id)
      )

    {:ok, assign_new(socket, :current_user, fn -> Auth.get_user!(user_id) end)}
  end

  defp show_encouraging_message(user_id) do
    Enum.all?([
      not Queue.has_participated?(%User{id: user_id}, :today),
      Queue.num_unplayed() == 0
    ])
  end

  #
  # Subscription handlers
  #

  # Playback state update
  @impl true
  def handle_info({PlayState, %{} = play_state, :play_state}, socket) do
    {:noreply, assign(socket, play_state: play_state, page_title: page_title(play_state))}
  end

  # Progress update (interpolated from timer)
  def handle_info({PlayState, progress, :progress}, socket) do
    {:noreply, assign(socket, progress: progress)}
  end

  # Metadata webhook. Player is playing something else now
  def handle_info({PlayState, %{} = metadata, :metadata}, socket) do
    {:noreply,
     assign(socket,
       metadata: metadata,
       page_title: page_title(metadata),
       show_encouraging_message: false
     )}
  end

  # Clear errormode
  def handle_info({PlayState, nil, :sonos_error}, socket) do
    {:noreply, clear_flash(socket, :error)}
  end

  def handle_info({PlayState, %{error_code: error_code}, :sonos_error}, socket) do
    {:noreply, put_flash(socket, :error, "😵 Oh shit, an error from Sonos: \"#{error_code}\"")}
  end

  # Queue has changed either from addition or track has played
  def handle_info({Music, _num_unplayed, :queue_updated}, socket) do
    send(self(), {:get_playlist, nil})
    {:noreply, socket}
  end

  # Someone got a point. Was it me?
  def handle_info({Music, %Point{track: %Track{name: name} = track}, :point}, socket) do
    send(self(), {:get_playlist, nil})

    if it_me?(track, socket) do
      socket =
        socket
        |> put_flash(:info, "🙌 You've received a unit of appreciation for \"#{name}\"")
        |> assign(recently_liked: track)

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  def handle_info(
        {Music, :flash, {level, message, user_id}},
        %{assigns: %{current_user: %User{id: requester_user_id}}} = socket
      )
      when requester_user_id == user_id do
    {:noreply, put_flash(socket, level, message)}
  end

  def handle_info({Music, :flash, {level, message, nil}}, socket) do
    {:noreply, put_flash(socket, level, message)}
  end

  def handle_info({Music, _, _}, socket) do
    {:noreply, socket}
  end

  #
  # Async UI functions
  #
  def handle_info({:search, ""}, socket) do
    # Empty serach query
    {:noreply, assign(socket, loading: false, result: [])}
  end

  def handle_info({:search, q}, socket) do
    case Music.search(q) do
      {:ok, tracks} ->
        {:noreply, assign(socket, loading: false, result: tracks)}

      _ ->
        {:noreply, assign(socket, loading: false, result: [])}
    end
  end

  def handle_info({:get_playlist, _}, %{assigns: %{current_user: user}} = socket) do
    items = Music.get_playlist(user)
    {:noreply, assign(socket, playlist: items)}
  end

  def handle_info({:queue, spotify_id}, %{assigns: %{current_user: user}} = socket) do
    case Music.queue(user, spotify_id) do
      {:ok, _track} ->
        {:noreply, assign(socket, loading: false, result: [], q: nil)}

      _ ->
        {:noreply, assign(socket, loading: false)}
    end
  end

  def handle_info({:like, track_id}, %{assigns: %{current_user: %User{id: user_id}}} = socket) do
    Scoring.create_point(%{track_id: track_id, user_id: user_id})
    send(self(), {:get_playlist, nil})
    {:noreply, socket}
  end

  ## User events

  @impl true
  def handle_event("queue", %{"value" => spotify_id}, socket) do
    send(self(), {:queue, spotify_id})
    {:noreply, assign(socket, participated: true)}
  end

  def handle_event("search", %{"q" => q}, socket) when byte_size(q) <= 100 do
    send(self(), {:search, q})
    {:noreply, assign(socket, q: q, result: [], loading: true)}
  end

  def handle_event("like", %{"value" => track_id}, socket) do
    send(self(), {:like, track_id})
    {:noreply, socket}
  end

  # This is all happening cos the @page_title is a single var and cant match playback_state and metadata in the template
  defp page_title(%PlaybackState{state: :paused}), do: "⏸️"
  defp page_title(%PlaybackState{state: :idle}), do: "..."

  defp page_title(%PlaybackState{state: :playing}),
    do: :metadata |> PlayState.get() |> page_title()

  defp page_title(%{current_item: %SonosItem{name: name, artist: artist}}) do
    case PlayState.get(:play_state) do
      %PlaybackState{state: :playing} ->
        "🎵 #{name} – #{artist}"

      _ ->
        "..."
    end
  end

  defp page_title(_), do: "..."
end
