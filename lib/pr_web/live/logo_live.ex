defmodule PRWeb.LogoLive do
  use Phoenix.LiveView
  # Use for stuff like img_tag till those are <.img etc
  use Phoenix.HTML
  use PRWeb, :html

  alias PR.PlayState

  # TMP do this to get these until they're components
  import PRWeb.PlaybackView
  import PRWeb.UserHeaderView
  import PRWeb.SharedView

  embed_templates "*"

  def mount(_params, _session, socket) do
    if connected?(socket), do: PlayState.subscribe()
    play_state = PlayState.get(:play_state)

    socket =
      assign(
        socket,
        play_state: play_state
      )

    {:ok, socket}
  end

  # Playback state update
  def handle_info({PlayState, %{} = play_state, :play_state}, socket) do
    {:noreply, assign(socket, play_state: play_state)}
  end

  def handle_info({PlayState, _, _}, socket) do
    {:noreply, socket}
  end
end
