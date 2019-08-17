defmodule EWeb.PlaybackLive do
  use Phoenix.LiveView
  use Phoenix.HTML

  alias E.SonosAPI

  @states %{
    "PLAYBACK_STATE_PAUSED" => "Play",
    "PLAYBACK_STATE_BUFFERING" => "Pause",
    "PLAYBACK_STATE_PLAYING" => "Pause"
  }

  def render(assigns) do
    ~L"""
    <div>
      <p>
        <button phx-click="toggle" class="<%= @toggling %> button"><%= play_label @play_state.playback_state %></button>
        <%= if assigns[:metadata], do: "#{@metadata.current_item.track.name} – #{@metadata.current_item.track.artist.name}" %>
      </p>
      <progress max="<%= @metadata.current_item.track.duration_millis %>" value="<%= @play_state.position_millis %>">

      <p><%= if assigns[:metadata], do: img_tag(@metadata.current_item.track.image_url, width: 200, height: 200) %></p>
    </div>
    """
  end

  def mount(_session, socket) do
    if connected?(socket), do: E.PlayState.subscribe()
    # TODO get these from Agent or something when new live view loads!
    play_state = SonosAPI.get_playback()
    metadata = SonosAPI.get_metadata()

    {:ok, assign(socket, toggling: "", metadata: metadata, play_state: play_state)}
  end

  def handle_info({E.PlayState, %{} = play_state, :play_state}, socket) do
    {:noreply, assign(socket, play_state: play_state, toggling: "")}
  end

  def handle_info({E.PlayState, %{} = metadata, :metadata}, socket) do
    {:noreply, assign(socket, metadata: metadata)}
  end

  def handle_event("toggle", _, socket) do
    E.SonosAPI.toggle_playback()
    {:noreply, assign(socket, toggling: "is-pending")}
  end

  defp play_label(state), do: Map.get(@states, state, "Play")
end

