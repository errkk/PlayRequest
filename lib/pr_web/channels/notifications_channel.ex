defmodule PRWeb.NotificationsChannel do
  use PRWeb, :channel
  require Logger

  alias PR.Music
  alias PR.Scoring.Point
  alias PR.Queue.Track

  def join("notifications:like", _payload, socket) do
    Music.subscribe()

    if authorized?(socket) do
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
      :ok
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
