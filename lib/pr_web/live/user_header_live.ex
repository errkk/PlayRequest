defmodule PRWeb.UserHeaderLive do
  require Logger
  use Phoenix.LiveView
  use Phoenix.HTML

  alias PR.Auth
  alias PR.Auth.User
  alias PR.Music
  alias PR.PlayState
  alias PR.Scoring
  alias PR.Scoring.Point
  alias PR.Queue.Track
  alias PR.Queue
  alias PR.SonosAPI
  alias PRWeb.PlaybackView
  alias PRWeb.UserHeaderView
  alias PRWeb.Presence

  @presence "presence"

  @impl true
  def render(assigns) do
    UserHeaderView.render("index.html", assigns)
  end

  @impl true
  def mount(_params, %{"user_id" => user_id}, socket) when not is_nil(user_id) do
    if connected?(socket), do: Music.subscribe()
    if connected?(socket), do: PlayState.subscribe()
    play_state = PlayState.get(:play_state)

    # Register user on presence, and push the current presence state out
    if connected?(socket) do
      {:ok, _} = Presence.track(self(), @presence, user_id, %{
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
      |> assign(:users, %{}) # Empty map to append on join/leave
      |> handle_joins(Presence.list(@presence))

    {:ok, assign_new(socket, :current_user, fn -> Auth.get_user!(user_id) end)}
  end

  def mount(_, _, socket) do
    socket =
      assign(
        socket,
        points: 0
      )

    {:ok, socket}
  end

  #
  # Subscription handlers
  #

  def handle_info(
        {Music, %Point{track: %Track{} = track}, :point},
        %{assigns: %{current_user: %User{id: user_id}}} = socket
      ) do
    if PlaybackView.it_me?(track, socket) do
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

  @impl true
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
    {:noreply, socket}
  end

  def handle_event("start", _, socket) do
    Music.trigger_playlist()
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
