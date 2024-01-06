defmodule PRWeb.LogoLive do
  # This is a small live view embedeed in PlaybackLive or in Controllers
  # live_render needs socket or conn so there is a live and an app layout
  # They're the same tho.
  # Small embedded live_views need to use this lighter layout so that live.html.heex
  # doesn't re-import UserHeaderLive and LogoLive again!
  use Phoenix.LiveView, layout: {PRWeb.Layouts, :live_embedded}
  use PRWeb, :helpers

  alias PR.PlayState
  alias PR.Music.PlaybackState

  import PRWeb.LogoSvg

  @impl true
  def render(assigns) do
    ~H"""
    <h1 class="logo-heading">
      <.link href={~p"/"} class="logo-link">
        <.logo play_state={@play_state} />
        <%= installation_name() %>
      </.link>
    </h1>
    """
  end

  def logo(%{play_state: %PlaybackState{state: :playing}} = assigns) do
    ~H"""
    <.logo_svg playing={true} />
    """
  end

  def logo(%{play_state: %PlaybackState{state: :buffering}} = assigns) do
    ~H"""
    <.logo_svg buffering={true} />
    """
  end

  def logo(%{play_state: _} = assigns) do
    ~H"""
    <.logo_svg />
    """
  end

  @impl true
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
  @impl true
  def handle_info({PlayState, %{} = play_state, :play_state}, socket) do
    {:noreply, assign(socket, play_state: play_state)}
  end

  def handle_info({PlayState, _, _}, socket) do
    {:noreply, socket}
  end
end
