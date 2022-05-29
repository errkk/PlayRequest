defmodule PRWeb.UserSocket do
  require Logger
  use Phoenix.Socket, log: false

  channel "notifications:*", PRWeb.NotificationsChannel

  def connect(%{"token" => token}, socket, _connect_info) do
    IO.inspect(token)
    # max_age: 1209600 is equivalent to two weeks in seconds
    case Phoenix.Token.verify(socket, "user socket", token, max_age: 1209600) do
      {:ok, user_id} ->
        {:ok, assign(socket, :user_id, user_id)}
      {:error, reason} ->
        IO.inspect(reason)
        :error
    end
  end

  def id(socket), do: "user_socket:#{socket.assigns.user_id}"
end
