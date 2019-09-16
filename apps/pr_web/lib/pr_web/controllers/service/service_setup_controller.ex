defmodule PRWeb.Service.ServiceSetupController do
  use PRWeb, :controller

  alias PR.SonosAPI
  alias PR.SpotifyAPI
  alias PR.SpotifyData
  alias PR.SonosHouseholds
  alias PR.ExternalAuth
  alias PR.Music

  def index(conn, _params) do
    households = SonosHouseholds.list_houeholds()
    groups = SonosHouseholds.list_groups()
    spotify_playlists = SpotifyData.list_playlists()

    sonos_auth_link = SonosAPI.get_auth_link!()
    spotify_auth_link = SpotifyAPI.get_auth_link!()

    sonos_token = ExternalAuth.get_auth(SonosAPI)
    spotify_token = ExternalAuth.get_auth(SpotifyAPI)

    has_active_households = households
    |> Enum.any?(& &1.is_active)
    has_active_groups = groups
    |> Enum.any?(& &1.is_active)

    active_group_subscribed = groups
    |> Enum.any?(& &1.is_active and not is_nil(&1.subscribed_at))

    render(
      conn,
      "index.html",
      households: households,
      groups: groups,
      sonos_auth_link: sonos_auth_link,
      spotify_auth_link: spotify_auth_link,
      has_token_sonos: not is_nil(sonos_token),
      has_token_spotify: not is_nil(spotify_token),
      has_households: [] != households,
      has_groups: [] != groups,
      has_active_households: has_active_households,
      has_active_groups: has_active_groups,
      active_group_subscribed: active_group_subscribed,
      spotify_playlist_created: [] != spotify_playlists
    )
  end

  def save_households(conn, _) do
    case SonosAPI.save_households() do
      {:ok, total} ->
        conn
        |> put_flash(:info, "Saved #{total} households. Plz activate one.")
        |> redirect(to: Routes.service_setup_path(conn, :index))
      {:error, msg} ->
        conn
        |> put_flash(:error, "⚠️ #{msg}")
        |> redirect(to: Routes.service_setup_path(conn, :index))
      _ ->
        conn
        |> put_flash(:error, "⚠️ Didn't work")
        |> redirect(to: Routes.service_setup_path(conn, :index))
    end
  end

  def save_groups(conn, _) do
    case SonosAPI.save_groups() do
      {:ok, total} ->
        conn
        |> put_flash(:info, "Saved #{total} groups. Plz activate one.")
        |> redirect(to: Routes.service_setup_path(conn, :index))
      {:error, msg} ->
        conn
        |> put_flash(:error, "⚠️ #{msg}")
        |> redirect(to: Routes.service_setup_path(conn, :index))
      _ ->
        conn
        |> put_flash(:error, "⚠️ Didn't work")
        |> redirect(to: Routes.service_setup_path(conn, :index))
    end
  end

  def toggle_household(conn, %{"id" => id}) do
    household = SonosHouseholds.get_household!(id)
    household
    |> SonosHouseholds.update_household(%{is_active: not household.is_active})

    conn
    |> redirect(to: Routes.service_setup_path(conn, :index))
  end

  def toggle_group(conn, %{"id" => id}) do
    group = SonosHouseholds.get_group!(id)
    group
    |> SonosHouseholds.update_group(%{is_active: not group.is_active})

    conn
    |> redirect(to: Routes.service_setup_path(conn, :index))
  end

  def subscribe_sonos_webhooks(conn, _) do
    case SonosAPI.subscribe_webhooks() do
      {:ok} ->
        conn
        |> put_flash(:info, "Subscribed to playback and metadata")
        |> redirect(to: Routes.service_setup_path(conn, :index))
      _ ->
        conn
        |> put_flash(:error, "⚠️ Didn't work")
        |> redirect(to: Routes.service_setup_path(conn, :index))
    end
  end

  def create_spotify_playlist(conn, _) do
    case SpotifyAPI.create_playlist() do
      {:ok, _, spotify_id} ->
        conn
        |> put_flash(:info, "Playlist created on Spotify (#{spotify_id})")
        |> redirect(to: Routes.service_setup_path(conn, :index))
      {:error, msg} ->
        conn
        |> put_flash(:error, "⚠️ #{msg}")
        |> redirect(to: Routes.service_setup_path(conn, :index))
    end
  end

  def sync_playlist(conn, _) do
    case Music.sync_playlist() do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Playlist synced")
        |> redirect(to: Routes.service_setup_path(conn, :index))
      _ ->
        conn
        |> put_flash(:error, "⚠️ There was an error syncing the playlist")
        |> redirect(to: Routes.service_setup_path(conn, :index))
    end
  end

  def load_playlist(conn, _) do
    case Music.load_playlist() do
      {:ok} ->
        conn
        |> put_flash(:info, "That seemed to work")
        |> redirect(to: Routes.service_setup_path(conn, :index))
      {:error, msg} ->
        conn
        |> put_flash(:error, "⚠️ #{msg}")
        |> redirect(to: Routes.service_setup_path(conn, :index))
    end
  end

  def bump(conn, _) do
    case Music.bump_and_reload() do
      {:ok} ->
        conn
        |> put_flash(:info, "That seemed to work")
        |> redirect(to: Routes.service_setup_path(conn, :index))
      {:error, msg} ->
        conn
        |> put_flash(:error, "⚠️ #{msg}")
        |> redirect(to: Routes.service_setup_path(conn, :index))
    end
  end

end

