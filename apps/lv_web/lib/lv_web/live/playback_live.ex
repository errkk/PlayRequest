defmodule EWeb.PlaybackLive do
  require IEx
  require Logger
  use Phoenix.LiveView
  use Phoenix.HTML

  alias E.{SonosAPI, SpotifyAPI, PlayState}

  @states %{
    "PLAYBACK_STATE_PAUSED" => "Play",
    "PLAYBACK_STATE_BUFFERING" => "Pause",
    "PLAYBACK_STATE_PLAYING" => "Pause"
  }

  def render(%{metadata: %{current_item: current_item}} = assigns) do
    ~L"""
    <div>
      <p>
        <button phx-click="toggle" class="<%= @toggling %> button"><%= play_label @play_state.playback_state %></button>
        <%= if assigns[:metadata], do: "#{@metadata.current_item.track.name} – #{@metadata.current_item.track.artist.name}" %>
      </p>
      <progress max="<%= @metadata.current_item.track.duration_millis %>" value="<%= @play_state.position_millis %>"></progress>

      <p><%= if assigns[:metadata], do: img_tag(@metadata.current_item.track.image_url, width: 200, height: 200) %></p>
    </div>
    """
  end

  def render(assigns) do
    ~L"""
    <div>
      <form phx-submit="search">
        <input type="text" name="q" value="<%= @q %>" <%= if @loading, do: "readonly" %>/>
      </form>
      <div>
        <%= for track <- @result do %>
          <p>
            <%= track.name %><br />
            <%= track.artist %>
          </p>
        <% end %>
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

    {:ok, assign(socket, toggling: "", metadata: metadata, play_state: play_state, result: [], q: nil, loading: nil)}
  end

  def handle_info({PlayState, %{} = play_state, :play_state}, socket) do
    {:noreply, assign(socket, play_state: play_state, toggling: "")}
  end

  def handle_info({PlayState, %{} = metadata, :metadata}, socket) do
    {:noreply, assign(socket, metadata: metadata)}
  end

  def handle_info({:search, q}, socket) do
    case SpotifyAPI.search(q) do
      {:ok, tracks} ->
        {:noreply, assign(socket, loading: false, result: tracks)}
      _ ->
        {:noreply, assign(socket, loading: false, result: [])}
    end
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

