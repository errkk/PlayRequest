defmodule PRWeb.NotificationsChannel do
  use PRWeb, :channel

  alias PR.Music
  alias PR.Queue.Track

  intercept ["like"]

  def join("notifications:like", _payload, socket) do
    Music.subscribe()

    if authorized?(socket) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  # PubSub callbacks from Music subscription
  def handle_info({Music, %Track{user_id: recipient_id} = track, :point},
      %{assigns: %{user_id: s_uid}} = socket) when recipient_id == s_uid do
    track_data = Map.take(track, [:name, :artist, :img])
    push(socket, "like", %{user_id: recipient_id, track: track_data})
    {:noreply, socket}
  end
  def handle_info({Music, _, _}, socket) do
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(%{assigns: user_id}) when not is_nil(user_id) do
    true
  end

  defp authorized?(_) do
    false
  end
end
