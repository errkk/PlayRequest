defmodule PRWeb.Plug.UserSocketToken do
  @moduledoc false

  use PRWeb, :plug

  def init(opts), do: opts

  def call(conn, _) do
    if current_user = conn.assigns[:current_user] do
      token = PRWeb.UserSocketToken.sign(conn, current_user.id)
      assign(conn, :user_token, token)
    else
      conn
    end
  end
end
