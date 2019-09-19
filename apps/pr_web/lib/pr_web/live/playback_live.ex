defmodule PRWeb.PlaybackLive do
  require Logger
  use Phoenix.LiveView
  use Phoenix.HTML

  alias PR.{SonosAPI, Music, PlayState}
  alias PR.Music.PlaybackState
  alias PR.Queue.Track
  alias PR.Auth
  alias PR.Auth.User

  def render(assigns) do
    ~L"""
    <div class="container">
      <div class="col--header--left">
        <h2>Search</h2>
      </div>
      <div class="col--search">
        <form phx-submit="search">
          <input autocomplete="off" type="text" name="q" value="<%= @q %>" <%= if @loading, do: "readonly" %>/>
        </form>
        <div class="search-results">
          <%= for track <- @result do %>
            <div class="track">
              <%= img_tag track.img, width: 100, class: "track__img" %>
              <div class="track__details">
                <h3 class="track__name">
                  <%= track.name %>
                </h3>
                <p class="track__artist">
                  <%= track.artist %>
                </p>
              </div>
              <button class="button" phx-click="queue" value="<%= track.spotify_id %>">Queue</button>
            </div>
          <% end %>
        </div>
      </div>

      <div class="col--header--right">
        <h2>Queue</h2>
      </div>
      <div class="col--playlist">
        <div class="queue">
          <%= for track <- @playlist do %>
            <div class="track">
              <%= img_tag track.img, width: 100, class: "track__img" %>
              <div class="track__details">
                <h3 class="track__name">
                  <%= track.name %>
                  <%= if playing?(track, @play_state), do: "▸" %>
                </h3>
                <p class="track__artist">
                  <%= track.artist %>
                  <%= if playing?(track, @play_state) do %>
                    <progress value="<%= @play_state.position %>" max="<%= track.duration %>" />
                  <% end %>
               </p>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  def playing?(%Track{playing_since: playing}, %PlaybackState{state: :playing}) when not is_nil(playing), do: true
  def playing?(_, _), do: false

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
      playlist: Music.get_playlist(),
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

  def handle_info({:get_playlist, _}, socket) do
    items = Music.get_playlist()
    {:noreply, assign(socket, playlist: items)}
  end

  def handle_info({:queue, spotify_id}, %{assigns: %{current_user: user}} = socket) do
    case Music.queue(user, spotify_id) do
      {:ok, _track} ->
        {:noreply, assign(socket, loading: false, result: [])}
      _ ->
        {:noreply, assign(socket, loading: false)}
    end
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

end

