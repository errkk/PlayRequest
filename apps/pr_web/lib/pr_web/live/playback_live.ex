defmodule PRWeb.PlaybackLive do
  require Logger
  use Phoenix.LiveView
  use Phoenix.HTML

  alias PR.{SonosAPI, Music, PlayState}
  alias PR.Auth
  alias PR.Auth.User
  alias PR.Scoring
  alias PR.Scoring.Point
  alias PR.Queue.Track
  alias PRWeb.PlaybackView

  def render(assigns) do
    PlaybackView.render("index.html", assigns)
  end

  def mount(%{user_id: user_id}, socket) do
    if connected?(socket), do: PlayState.subscribe()
    if connected?(socket), do: Music.subscribe()
    Logger.info "Mounting a new live view"
    play_state = PlayState.get(:play_state)
    metadata = PlayState.get(:metadata)

    socket = assign(
      socket,
      metadata: metadata,
      play_state: play_state,
      result: [],
      q: nil,
      loading: nil,
      info: nil,
      recently_liked: nil,
      playlist: Music.get_playlist(%User{id: user_id}),
    )

    {:ok, assign_new(socket, :current_user, fn -> Auth.get_user!(user_id) end)}
  end

  #
  # Subscription handlers
  #

  # Progress update
  def handle_info({PlayState, %{} = play_state, :play_state}, socket) do
    {:noreply, assign(socket, play_state: play_state)}
  end

  # Metadata webhook. Player is playing something else now
  def handle_info({PlayState, %{} = metadata, :metadata}, socket) do
    send(self(), {:get_playlist, nil})
    {:noreply, assign(socket, metadata: metadata)}
  end

  # Queue updated
  def handle_info({Music, %{} = track, :added}, socket) do
    send(self(), {:get_playlist, nil})
    {:noreply, socket}
  end

  def handle_info({Music, %Track{name: name} = track, :point}, socket) do
    send(self(), {:get_playlist, nil})
    if PlaybackView.it_me?(track, socket) do
      {:noreply, assign(socket, info: "🙌 You've received a unit of appreciation for \"#{name}\"", recently_liked: track)}
    else
      {:noreply, socket}
    end
  end

  #
  # Async UI functions
  #

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

  def handle_event("queue", spotify_id, socket) do
    send(self(), {:queue, spotify_id})
    {:noreply, socket}
  end

  def handle_event("search", %{"q" => q}, socket) when byte_size(q) <= 100 do
    send(self(), {:search, q})
    {:noreply, assign(socket, q: q, result: [], loading: true)}
  end

  def handle_event("like", track_id, socket) do
    send(self(), {:like, track_id})
    {:noreply, socket}
  end

  def handle_event("clear_info", _, socket) do
    {:noreply, assign(socket, info: nil)}
  end

end

