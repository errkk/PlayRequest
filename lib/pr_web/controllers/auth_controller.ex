defmodule PRWeb.AuthController do
  use PRWeb, :controller
  plug(Ueberauth)

  alias PR.Auth

  def index(conn, _params) do
    render(conn, :index)
  end

  def request(conn, _params) do
    render(conn, :index)
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "You have been logged out!")
    |> configure_session(drop: true)
    |> redirect(to: ~p"/auth/")
  end

  def callback(%{assigns: %{ueberauth_failure: _fails}} = conn, _params) do
    conn
    |> put_flash(:error, "Failed to authenticate.")
    |> redirect(to: ~p"/auth/")
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    with flattened <- Auth.User.from_auth(auth),
         {:ok, user} <- Auth.find_or_create_user(flattened) do
      conn
      |> put_session(:user_id, user.id)
      |> configure_session(renew: true)
      |> redirect(to: ~p"/")
    else
      {:error, %Ecto.Changeset{errors: [email: _]}} ->
        conn
        |> put_flash(:error, "Wrong domain")
        |> redirect(to: ~p"/auth/")

      {:error, reason} ->
        conn
        |> put_flash(:error, reason)
        |> redirect(to: ~p"/auth/")
    end
  end
end
