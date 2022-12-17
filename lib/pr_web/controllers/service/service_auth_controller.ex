defmodule PRWeb.Service.ServiceAuthController do
  use PRWeb, :controller

  alias PR.SonosAPI
  alias PR.SpotifyAPI

  def authorized_sonos(conn, params) do
    case SonosAPI.handle_auth_callback(params) do
      {:ok} ->
        conn
        |> put_flash(:info, "That worked fine")
        |> redirect(to: ~p"/setup")

      {:error, _} ->
        conn
        |> put_flash(:error, "Didn't work")
        |> redirect(to: ~p"/setup")
    end
  end

  def authorized_spotify(conn, params) do
    case SpotifyAPI.handle_auth_callback(params) do
      {:ok} ->
        conn
        |> put_flash(:info, "That worked fine")
        |> redirect(to: ~p"/setup")

      {:error, _} ->
        conn
        |> put_flash(:error, "Didn't work")
        |> redirect(to: ~p"/setup")
    end
  end
end
