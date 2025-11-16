defmodule PRWeb.Plug.AuthPlug do
  @moduledoc false

  use PRWeb, :plug
  alias PR.Auth.User
  alias PR.Auth
  require Logger

  def init(opts), do: opts

  def call(conn, _) do
    user_id = get_session(conn, :user_id)
    Logger.debug("AuthPlug: user_id from session: #{inspect(user_id)}")
    Logger.debug("AuthPlug: path: #{conn.request_path}")

    user_id
    |> get_user(conn)
  end

  defp get_user(nil, conn) do
    Logger.debug("AuthPlug: No user_id in session, redirecting to /auth")
    nope(conn)
  end

  defp get_user(user_id, conn) do
    Logger.debug("AuthPlug: Looking up user_id: #{inspect(user_id)}")

    case Auth.get_user(user_id) do
      %User{} = user ->
        Logger.debug("AuthPlug: User found: #{inspect(user.id)}")

        conn
        |> put_session(:user_id, user_id)
        |> assign(:current_user, user)

      _ ->
        Logger.debug("AuthPlug: User not found in database for user_id: #{inspect(user_id)}")
        nope(conn)
    end
  end

  defp nope(conn) do
    conn
    |> redirect(to: ~p"/auth")
    |> halt()
  end
end
