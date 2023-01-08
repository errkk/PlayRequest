defmodule PRWeb.NotificationsChannel do
  use PRWeb, :channel
  require Logger

  alias PR.Music
  alias PR.PlayState
  alias PR.Scoring.Point
  alias PR.Queue.Track

  def join("notifications:*", _payload, socket) do
    Music.subscribe()
    PlayState.subscribe()

    if authorized?(socket) do
      send(self(), {:after_join, nil})
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # PubSub callbacks from Music subscription
  def handle_info({Music, point, :point}, socket) do
    %Point{track: %Track{user_id: recipient_id} = track, user: user} = point

    track_data = Map.take(track, [:name, :artist, :img])
    user_data = Map.take(user, [:first_name, :last_name])

    case socket do
      %{assigns: %{user_id: ^recipient_id}} ->
        Logger.info("Sending like to user:#{recipient_id}")
        push(socket, "like", %{user_id: recipient_id, track: track_data, from: user_data})

      _ ->
        :ok
    end

    {:noreply, socket}
  end

  def handle_info({PlayState, nil, :sonos_error}, socket) do
    push(socket, "error", %{error_code: nil})
    {:noreply, socket}
  end

  def handle_info({PlayState, %{error_code: error_code}, :sonos_error}, socket) do
    Logger.debug("Channel: Sending errror")
    push(socket, "error", %{error_code: error_code})
    {:noreply, socket}
  end

  def handle_info({PlayState, %{state: state}, :play_state}, socket) do
    Logger.debug("Channel: Sending playstate")
    push(socket, "play_state", %{state: state})
    {:noreply, socket}
  end

  # Send from self on join
  def handle_info({:after_join, _}, socket) do
    # Get playstate from the agent and push it on the socket
    # just like we do here on info from Playstate pubsub
    case PlayState.get(:play_state) do
      %Music.PlaybackState{state: state} ->
        push(socket, "play_state", %{state: state})

      _ ->
        push(socket, "play_state", %{state: nil})
    end

    {:noreply, socket}
  end

  def handle_info(_, socket) do
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(%{assigns: %{user_id: user_id}}) when not is_nil(user_id) do
    true
  end

  defp authorized?(_) do
    false
  end
end
