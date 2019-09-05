defmodule PRWeb.Service.ServiceAuthController do
  use PRWeb, :controller

  alias PR.SonosAPI
  alias PR.SpotifyAPI

  def index(conn, _params) do
    sonos_auth_link = SonosAPI.get_auth_link!()
    spotify_auth_link = SpotifyAPI.get_auth_link!()
    render(conn, "index.html", sonos_auth_link: sonos_auth_link, spotify_auth_link: spotify_auth_link)
  end

  def authorized_sonos(conn, params) do
    case SonosAPI.handle_auth_callback(params) do
      {:ok} ->
        conn
        |> put_flash(:info, "That worked fine")
        |> redirect(to: Routes.page_path(conn, :index))
      {:error, _} ->
        conn
        |> put_flash(:error, "Didn't work")
        |> redirect(to: Routes.service_auth_path(conn, :index))
    end
  end

  def authorized_spotify(conn, params) do
    case SpotifyAPI.handle_auth_callback(params) do
      {:ok} ->
        conn
        |> put_flash(:info, "That worked fine")
        |> redirect(to: Routes.page_path(conn, :index))
      {:error, _} ->
        conn
        |> put_flash(:error, "Didn't work")
        |> redirect(to: Routes.service_auth_path(conn, :index))
    end
  end
end
