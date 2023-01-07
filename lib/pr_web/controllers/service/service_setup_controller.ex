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

    has_active_households =
      households
      |> Enum.any?(& &1.is_active)

    has_active_groups =
      groups
      |> Enum.any?(& &1.is_active)

    active_group_subscribed =
      groups
      |> Enum.any?(&(&1.is_active and not is_nil(&1.subscribed_at)))

    render(
      conn,
      :index,
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
        |> redirect(to: ~p"/setup")

      _ ->
        conn
        |> put_flash(:error, "Didn't work")
        |> redirect(to: ~p"/setup")
    end
  end

  def save_groups(conn, _) do
    case SonosAPI.save_groups() do
      {:ok, total} ->
        conn
        |> put_flash(:info, "Saved #{total} groups. Plz activate one.")
        |> redirect(to: ~p"/setup")

      {:error, msg} ->
        conn
        |> put_flash(:error, msg)
        |> redirect(to: ~p"/setup")

      _ ->
        conn
        |> put_flash(:error, "Didn't work")
        |> redirect(to: ~p"/setup")
    end
  end

  def toggle_household(conn, %{"id" => id}) do
    household = SonosHouseholds.get_household!(id)

    household
    |> SonosHouseholds.update_household(%{is_active: not household.is_active})

    conn
    |> redirect(to: ~p"/setup")
  end

  def toggle_group(conn, %{"id" => id}) do
    group = SonosHouseholds.get_group!(id)

    group
    |> SonosHouseholds.update_group(%{is_active: not group.is_active})

    conn
    |> redirect(to: ~p"/setup")
  end

  def subscribe_sonos_webhooks(conn, _) do
    case SonosAPI.subscribe_webhooks() do
      {:ok} ->
        conn
        |> put_flash(:info, "Subscribed to playback and metadata")
        |> redirect(to: ~p"/setup")

      _ ->
        conn
        |> put_flash(:error, "Didn't work")
        |> redirect(to: ~p"/setup")
    end
  end

  def create_spotify_playlist(conn, _) do
    case SpotifyAPI.create_playlist() do
      {:ok, _, spotify_id} ->
        conn
        |> put_flash(:info, "Playlist created on Spotify (#{spotify_id})")
        |> redirect(to: ~p"/setup")

      {:error, msg} ->
        conn
        |> put_flash(:error, msg)
        |> redirect(to: ~p"/setup")
    end
  end

  def sync_playlist(conn, _) do
    case Music.sync_playlist() do
      {:ok, _} ->
        conn
        |> put_flash(:info, "Playlist synced")
        |> redirect(to: ~p"/setup")

      _ ->
        conn
        |> put_flash(:error, "There was an error syncing the playlist")
        |> redirect(to: ~p"/setup")
    end
  end

  def trigger_playlist(conn, _) do
    case Music.trigger_playlist() do
      {:ok} ->
        conn
        |> put_flash(:info, "That seemed to work")
        |> redirect(to: ~p"/setup")

      {:error, msg} ->
        conn
        |> put_flash(:error, msg)
        |> redirect(to: ~p"/setup")
    end
  end

  def bump(conn, _) do
    case Music.bump() do
      {:ok} ->
        conn
        |> put_flash(:info, "That seemed to work")
        |> redirect(to: ~p"/setup")

      {:error, msg} ->
        conn
        |> put_flash(:error, msg)
        |> redirect(to: ~p"/setup")
    end
  end

  def clear_groups(conn, _) do
    case SonosHouseholds.clear_groups() do
      {:ok} ->
        conn
        |> put_flash(:info, "That seemed to work")
        |> redirect(to: ~p"/setup")

      {:error, msg} ->
        conn
        |> put_flash(:error, msg)
        |> redirect(to: ~p"/setup")
    end
  end

  def get_state(conn, _) do
    PR.PlayState.get_initial_state()
    redirect(conn, to: ~p"/setup")
  end
end
