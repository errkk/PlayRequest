defmodule PRWeb.UserSocket do
  use Phoenix.Socket, log: false

  channel "notifications:*", PRWeb.NotificationsChannel

  def connect(params, socket, _connect_info) do
    {:ok, assign(socket, :user_id, params["user_id"])}
  end

  def id(socket), do: "user_socket:#{socket.assigns.user_id}"
end
