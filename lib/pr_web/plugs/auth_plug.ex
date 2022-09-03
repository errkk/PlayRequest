defmodule PRWeb.Plug.AuthPlug do
  @moduledoc false

  use PRWeb, :plug
  alias PR.Auth.User
  alias PR.Auth

  def init(opts), do: opts

  def call(conn, _) do
    conn
    |> get_session(:user_id)
    |> get_user(conn)
  end

  defp get_user(nil, conn) do
    nope(conn)
  end

  defp get_user(user_id, conn) do
    case Auth.get_user(user_id) do
      %User{} = user ->
        conn
        |> put_session(:user_id, user_id)
        |> assign(:current_user, user)

      _ ->
        nope(conn)
    end
  end

  defp nope(conn) do
    conn
    |> redirect(to: Routes.auth_path(conn, :index))
    |> halt()
  end
end
