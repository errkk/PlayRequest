defmodule PRWeb.Plug.UserSocketToken do
  @moduledoc false

  use PRWeb, :plug

  def init(opts), do: opts

  def call(conn, _) do
    IO.inspect conn.assigns
    if current_user = conn.assigns[:current_user] do
      token = Phoenix.Token.sign(conn, "user socket", current_user.id)
      assign(conn, :user_token, token)
    else
      conn
    end
  end

  defp get_release_metadata do
    [
      version: System.get_env("APP_REVISION", "dev"),
    ]
  end
end

