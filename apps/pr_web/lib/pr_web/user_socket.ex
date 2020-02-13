defmodule PRWeb.UserSocket do
  use Phoenix.Socket, log: false

  channel "notifications:*", PRWeb.NotificationsChannel

  def connect(_params, socket, connect_info) do
    user_id = connect_info.session["user_id"]
    {:ok, assign(socket, :user_id, user_id)}
  end

  def id(socket), do: "user_socket:#{socket.assigns.user_id}"
end
