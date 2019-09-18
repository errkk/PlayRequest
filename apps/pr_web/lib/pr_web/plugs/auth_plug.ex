defmodule PRWeb.Plug.AuthPlug do
  @moduledoc false
  @behaviour Plug

  use PRWeb, :plug
  alias PR.Auth.User
  alias PR.Auth

  def init(opts), do: opts

  def call(conn, _) do
    user_id = get_session(conn, :user_id)
    case Auth.get_user(user_id) do
        %User{} = user ->
          conn
          |> put_session(:user_id, user_id)
          |> assign(:current_user, user)
        _ ->
          conn
          |> redirect(to: Routes.auth_path(conn, :index))
      end
  end
end
