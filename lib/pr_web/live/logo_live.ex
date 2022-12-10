defmodule PRWeb.LogoLive do
  use PRWeb, :live_view

  alias PR.PlayState
  alias PR.Music.PlaybackState

  @impl true
  def render(assigns) do
    ~H"""
      <h1 class="logo-heading">
        <.link to={~p"/"} class="logo-link">
          <.logo play_state={@play_state} />
          <%= installation_name() %>
        </.link>
      </h1>
    """
  end

  def logo(%{play_state: %PlaybackState{state: :playing}} = assigns) do
    ~H"""
      <img src={~p"/images/playing.svg"} class="logo" />
    """
  end

  def logo(%{play_state: _} = assigns) do
    ~H"""
      <img src={~p"/images/not-playing.svg"} class="logo" />
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    IO.puts "mounting logo"
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
