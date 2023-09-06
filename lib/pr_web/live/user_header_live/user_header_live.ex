defmodule PRWeb.UserHeaderLive do
  require Logger
  # This is a small live view embedeed in PlaybackLive or in Controllers
  # live_render needs socket or conn so there is a live and an app layout
  # They're the same tho.
  # Small embedded live_views need to use this lighter layout so that live.html.heex
  # doesn't re-import UserHeaderLive and LogoLive again!
  use Phoenix.LiveView, layout: {PRWeb.Layouts, :live_embedded}
  use PRWeb, :helpers

  alias PR.Music
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

  # TODO: Move this
  import PRWeb.LogoLive, only: [is_deutsches_freitag?: 0]

  import PRWeb.Shared

  embed_templates("*")

  @presence "presence"

  @impl true
  def render(%{current_user: cu} = assigns) when not is_nil(cu) do
    ~H"""
    <div class="user-header">
      <.nav
        current_user={@current_user}
        points={@points}
        super_likes={@super_likes}
        show_super_like={@show_super_like}
      />
      <div class="playback-controls">
        <%= if (@show_toggle_playback or @current_user.is_trusted == true) and @num_unplayed > 0 do %>
          <.play_pause play_state={@play_state} show_skip={@show_skip && @num_unplayed > 1} />
        <% end %>
        <%= if @show_volume or @current_user.is_trusted do %>
          <.volume max_vol={@max_vol} />
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

  def fire(assigns) do
    ~H"""
    <img src={~p"/images/fire.svg"} class="fire" />
    """
  end

  def play_pause(%{play_state: %PlaybackState{state: :playing}} = assigns) do
    ~H"""
    <button class="button button--primary" phx-click="toggle_playback">Pause</button>
    <button :if={@show_skip} class="button" phx-click="skip">Skip</button>
    """
  end

  def play_pause(%{play_state: %PlaybackState{state: :buffering}} = assigns) do
    ~H"""
    <button class="button loading" phx-click="toggle_playback" disabled>Play</button>
    """
  end

  def play_pause(%{play_state: %PlaybackState{state: :paused}} = assigns) do
    ~H"""
    <button
      title="Resume playback of whatever was playing"
      class="button button--primary"
      phx-click="toggle_playback"
    >
      Resume
    </button>
    <button
      title="Trigger playlist again, if it's playing the wrong thing."
      class="button"
      phx-click="start"
    >
      Re-Start
    </button>
    """
  end

  def play_pause(%{play_state: %PlaybackState{state: :idle}} = assigns) do
    ~H"""
    <button class="button button--primary" phx-click="start">Start</button>
    """
  end

  def play_pause(assigns) do
    ~H"""
    <p>😵</p>
    """
  end

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

    %{likes: likes, super_likes: super_likes} = Scoring.count_likes_received(%User{id: user_id})

    socket =
      socket
      |> assign(
        points: likes,
        super_likes: super_likes,
        play_state: play_state,
        num_unplayed: Queue.num_unplayed(),
        max_vol: max_vol()
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
        points: 0,
        super_likes: 0
      )
      |> assign(feature_flags())

    {:ok, socket}
  end

  def max_vol() do
    if is_deutsches_freitag?() do
      35
    else
      25
    end
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
      %{likes: likes, super_likes: super_likes} = Scoring.count_likes_received(%User{id: user_id})

      {:noreply,
       assign(
         socket,
         points: likes,
         super_likes: super_likes
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

  def handle_info({Music, _, _}, socket) do
    # Can't do antying about this no flash, playback_live will do it
    {:noreply, socket}
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

  def handle_event("skip", _, socket) do
    %{assigns: %{current_user: %{first_name: name, id: user_id}}} = socket
    Logger.info("Skip track – #{name}")
    Music.skip(user_id)
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
