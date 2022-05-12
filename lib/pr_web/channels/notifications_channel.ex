defmodule PRWeb.NotificationsChannel do
  use PRWeb, :channel
  require Logger

  alias PR.Music
  alias PR.Scoring.Point
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
  def handle_info({Music, %Point{track: %Track{user_id: recipient_id} = track, user: user}, :point},
      %{assigns: %{user_id: s_uid}} = socket) when recipient_id == s_uid do
    track_data = Map.take(track, [:name, :artist, :img])
    user_data = Map.take(user, [:first_name, :last_name])
    push(socket, "like", %{user_id: recipient_id, track: track_data, from: user_data})
    %{name: name} = track_data
    %{first_name: first_name} = user_data
    Logger.info("Track liked: #{name} from: #{first_name}")
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
