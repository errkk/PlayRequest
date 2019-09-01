defmodule EWeb.PlaybackLive do
  require IEx
  require Logger
  use Phoenix.LiveView
  use Phoenix.HTML

  alias E.{SonosAPI, Music, PlayState}

  @states %{
    "PLAYBACK_STATE_PAUSED" => "Play",
    "PLAYBACK_STATE_BUFFERING" => "Pause",
    "PLAYBACK_STATE_PLAYING" => "Pause"
  }

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
              <button phx-click="queue" value="<%= track.spotify_id %>">Queue</button>
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
                </h3>
                <p class="track__artist">
                  <%= track.artist %>
                </p>
              </div>
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  def mount(_session, socket) do
    if connected?(socket), do: PlayState.subscribe()
    Logger.info "Mounting a new live view"
    # Set inital values from agent?
    play_state = PlayState.get(:play_state)
    metadata = PlayState.get(:metadata)

    {:ok, assign(
      socket,
      toggling: "",
      metadata: metadata,
      play_state: play_state,
      result: [],
      q: nil,
      loading: nil,
      playlist: Music.get_playlist()
    )}
  end

  def handle_info({PlayState, %{} = play_state, :play_state}, socket) do
    {:noreply, assign(socket, play_state: play_state, toggling: "")}
  end

  def handle_info({PlayState, %{} = metadata, :metadata}, socket) do
    {:noreply, assign(socket, metadata: metadata)}
  end

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

  def handle_info({:queue, spotify_id}, socket) do
    Logger.info("Queuing #{spotify_id}")
    case Music.queue(spotify_id) do
      {:ok, track} ->
        send(self(), {:get_playlist, nil})
        {:noreply, assign(socket, loading: false, result: [])}
      _ ->
        {:noreply, assign(socket, loading: false)}
    end
  end

  def handle_event("queue", spotify_id, socket) do
    send(self(), {:queue, spotify_id})
    {:noreply, socket}
  end

  def handle_event("toggle", _, socket) do
    SonosAPI.toggle_playback()
    {:noreply, assign(socket, toggling: "is-pending")}
  end

  def handle_event("search", %{"q" => q}, socket) when byte_size(q) <= 100 do
    send(self(), {:search, q})
    {:noreply, assign(socket, q: q, result: [], loading: true)}
  end

  defp play_label(state), do: Map.get(@states, state, "Play")
end

