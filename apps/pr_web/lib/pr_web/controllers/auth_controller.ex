defmodule PRWeb.AuthController do
  use PRWeb, :controller
  plug Ueberauth

  alias Ueberauth.Strategy.Helpers
  alias PR.Auth

  def index(conn, _params) do
    render(conn, "index.html")
  end

  def request(conn, _params) do
    render(conn, "index.html")
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "You have been logged out!")
    |> configure_session(drop: true)
    |> redirect(to: Routes.auth_path(conn, :index))
  end

  def callback(%{assigns: %{ueberauth_failure: _fails}} = conn, _params) do
    conn
    |> put_flash(:error, "Failed to authenticate.")
    |> redirect(to: Routes.auth_path(conn, :index))
  end

  def callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    with flattened <- Auth.User.from_auth(auth),
      {:ok, user} <- Auth.find_or_create_user(flattened) do
        conn
        |> put_session(:current_user, user)
        |> configure_session(renew: true)
        |> redirect(to: Routes.live_path(conn, PRWeb.PlaybackLive))
    else
      {:error, %Ecto.Changeset{errors: [email: _]}} ->
        conn
        |> put_flash(:error, "Wrong domain")
        |> redirect(to: Routes.auth_path(conn, :index))
      {:error, reason} ->
        conn
        |> put_flash(:error, reason)
        |> redirect(to: Routes.auth_path(conn, :index))
    end
  end
end
