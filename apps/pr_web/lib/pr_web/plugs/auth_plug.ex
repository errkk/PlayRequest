defmodule PRWeb.Plug.AuthPlug do
  @moduledoc false
  @behaviour Plug

  use PRWeb, :plug
  alias PR.Auth.User

  def init(opts), do: opts

  def call(conn, _) do
    case get_session(conn, :current_user) do
        %User{id: id} = user ->
          user = user
          |> Map.delete(:token)

          conn
          |> put_session(:user_id, id)
          |> assign(:current_user, user)
        _ ->
          conn
          |> redirect(to: Routes.auth_path(conn, :index))
      end
  end
end
