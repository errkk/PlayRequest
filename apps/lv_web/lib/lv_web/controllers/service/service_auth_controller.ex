defmodule EWeb.Service.ServiceAuthController do
  use EWeb, :controller

  alias E.{SonosAPI, SpotifyAPI}

  def index(conn, _params) do
    sonos_auth_link = SonosAPI.get_auth_link!()
    spotify_auth_link = SpotifyAPI.get_auth_link!()
    render(conn, "index.html", sonos_auth_link: sonos_auth_link, spotify_auth_link: spotify_auth_link)
  end

  def authorized_sonos(conn, params) do
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
