defmodule PRWeb.UserSocket do
  require Logger
  use Phoenix.Socket, log: false

  channel("notifications:*", PRWeb.NotificationsChannel)

  def connect(%{"token" => token}, socket, _connect_info) do
    case PRWeb.UserSocketToken.verify(socket, token) do
      {:ok, user_id} ->
        {:ok, assign(socket, :user_id, user_id)}

      {:error, _reason} ->
        :error
    end
  end

  def connect(%{}, _socket, _connect_info) do
    :error
  end

  def id(socket), do: "user_socket:#{socket.assigns.user_id}"
end
