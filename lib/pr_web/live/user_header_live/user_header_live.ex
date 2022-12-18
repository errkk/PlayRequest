defmodule PRWeb.UserHeaderLive do
  require Logger
  # This is a small live view embedeed in PlaybackLive or in Controllers
  # live_render needs socket or conn so there is a live and an app layout
  # They're the same tho.
  # Small embedded live_views need to use this lighter layout so that live.html.heex
  # doesn't re-import UserHeaderLive and LogoLive again!
  use Phoenix.LiveView, layout: {PRWeb.Layouts, :live_embedded}
  use PRWeb, :helpers

  alias PR.Auth
  alias PR.Auth.User
  alias PR.Music
  alias PR.Music.PlaybackState
  alias PR.PlayState
  alias PR.Scoring
  alias PR.Scoring.Point
  alias PR.Queue.Track
  alias PR.Queue
  alias PR.SonosAPI
  alias PRWeb.Presence

  import PRWeb.Shared

  embed_templates "*"

  @presence "presence"

  @impl true
  def render(%{current_user: cu} = assigns) when not is_nil(cu) do
    ~H"""
    <div class="user-header">
      <.nav current_user={@current_user} points={@points} />
      <div class="playback-controls">
        <%= if @show_toggle_playback or @current_user.is_trusted == true and @num_unplayed > 0 do %>
          <.play_pause play_state={@play_state} />
        <% end %>
        <%= if @show_volume or @current_user.is_trusted do %>
          <.volume />
        <% end %>
      </div>
      <.online_users users={@users} />
    </div>
    """
  end

  def render(assigns) do
    ~H"""
    <div class="user-header"></div>
    """
  end

  def heart(assigns) do
    ~H"""
    <img src={~p"/images/heart_pink.svg"} class="heart" />
    """
  end

  def play_pause(%{play_state: %PlaybackState{state: :playing}} = assigns) do
    ~H"""
    <button class="button" phx-click="toggle_playback">Pause</button>
    """
  end

  def play_pause(%{play_state: %PlaybackState{state: :buffering}} = assigns) do
    ~H"""
    <button class="button loading" phx-click="toggle_playback" disabled>Play</button>
    """
  end

  def play_pause(%{play_state: %PlaybackState{state: :paused}} = assigns) do
    ~H"""
    <button class="button" phx-click="toggle_playback">Play</button>
    """
  end

  def play_pause(%{play_state: %PlaybackState{state: :idle}} = assigns) do
    ~H"""
    <button class="button" phx-click="start">start</button>
    """
  end

  def play_pause(_, _), do: nil

  @impl true
  def mount(_params, %{"user_id" => user_id}, socket) when not is_nil(user_id) do
    if connected?(socket), do: Music.subscribe()
    if connected?(socket), do: PlayState.subscribe()
    play_state = PlayState.get(:play_state)

    # Register user on presence, and push the current presence state out
    if connected?(socket) do
      {:ok, _} =
        Presence.track(self(), @presence, user_id, %{
          online_at: inspect(System.system_time(:second))
        })

      PRWeb.Endpoint.subscribe(@presence)
    end

    socket =
      socket
      |> assign(
        points: Scoring.count_points(%User{id: user_id}),
        play_state: play_state,
        num_unplayed: Queue.num_unplayed()
      )
      # Empty map to append on join/leave
      |> assign(:users, %{})
      |> assign(feature_flags())
      |> handle_joins(Presence.list(@presence))

    {:ok, assign_new(socket, :current_user, fn -> Auth.get_user!(user_id) end)}
  end

  def mount(_, _, socket) do
    socket =
      assign(
        socket,
        points: 0
      )
      |> assign(feature_flags())

    {:ok, socket}
  end

  #
  # Subscription handlers
  #
  @impl true
  def handle_info(
        {Music, %Point{track: %Track{} = track}, :point},
        %{assigns: %{current_user: %User{id: user_id}}} = socket
      ) do
    if it_me?(track, socket) do
      {:noreply,
       assign(
         socket,
         points: Scoring.count_points(%User{id: user_id})
       )}
    else
      {:noreply, socket}
    end
  end

  def handle_info({PlayState, %{} = play_state, :play_state}, socket) do
    {:noreply, assign(socket, play_state: play_state)}
  end

  def handle_info({Music, num_unplayed, :queue_updated}, socket) do
    {:noreply, assign(socket, num_unplayed: num_unplayed)}
  end

  def handle_info(%Phoenix.Socket.Broadcast{event: "presence_diff", payload: diff}, socket) do
    {
      :noreply,
      socket
      |> handle_leaves(diff.leaves)
      |> handle_joins(diff.joins)
    }
  end

  def handle_info(_, socket) do
    {:noreply, socket}
  end

  #
  # UI events
  #

  @impl true
  def handle_event("toggle_playback", _, socket) do
    SonosAPI.toggle_playback()
    %{assigns: %{current_user: %{first_name: name}}} = socket
    Logger.info("Toggle playback – #{name}")
    {:noreply, socket}
  end

  def handle_event("start", _, socket) do
    Music.trigger_playlist()
    %{assigns: %{current_user: %{first_name: name}}} = socket
    Logger.info("Trigger playback – #{name}")
    {:noreply, socket}
  end

  def handle_event("volume", %{"value" => volume}, socket) do
    SonosAPI.set_volume(volume)
    %{assigns: %{current_user: %{first_name: name}}} = socket
    Logger.info("Vol #{volume} – #{name}")
    {:noreply, socket}
  end

  defp handle_joins(socket, joins) do
    Enum.reduce(joins, socket, fn {user, %{metas: _, user: user_data}}, socket ->
      assign(socket, :users, Map.put(socket.assigns.users, user, user_data))
    end)
  end

  defp handle_leaves(socket, leaves) do
    Enum.reduce(leaves, socket, fn {user, _}, socket ->
      assign(socket, :users, Map.delete(socket.assigns.users, user))
    end)
  end
end
