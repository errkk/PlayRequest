defmodule PRWeb.LogoLive do
  use Phoenix.LiveView
  use Phoenix.HTML

  alias PR.PlayState
  alias PRWeb.LogoView

  def render(assigns) do
    LogoView.render("index.html", assigns)
  end

  def mount(_, socket) do
    if connected?(socket), do: PlayState.subscribe()
    play_state = PlayState.get(:play_state)

    socket = assign(
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

