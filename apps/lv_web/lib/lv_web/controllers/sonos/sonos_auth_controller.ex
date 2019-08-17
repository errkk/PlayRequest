defmodule EWeb.Sonos.SonosAuthController do
  use EWeb, :controller

  alias E.SonosAPI

  def index(conn, _params) do
    login = SonosAPI.get_auth_link!()
    render(conn, "index.html", auth_link: login)
  end

  def authorized(conn, params) do
    case SonosAPI.handle_auth_callback(params) do
      {:error, _} ->
        conn
        |> put_flash(:error, "Didn't work")
        |> redirect(to: Routes.sonos_auth_path(conn, :index))
      {:ok} ->
        conn
        |> put_flash(:info, "That worked fine")
        |> redirect(to: Routes.page_path(conn, :index))
    end
  end
end
