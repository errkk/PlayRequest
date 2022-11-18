defmodule PR.SpotifyAPI do
  use PR.Apis.TokenHelper
  use PR.Apis.EndpointHelper

  alias OAuth2.{Client, Strategy}
  alias PR.SpotifyData
  alias PR.SpotifyData.Playlist

  def get_devices do
    get("/v1/me/player/devices")
  end

  def get_playlists do
    get("/v1/me/playlists")
  end

  def get_current_user do
    get("/v1/me")
  end

  def create_playlist do
    with %{id: spotify_id} <- get_current_user(),
         %{id: playlist_id} <-
           post(%{name: get_playlist_name(), public: false}, "/v1/users/#{spotify_id}/playlists") do
      SpotifyData.create_playlist(%{playlist_id: playlist_id, spotify_id: spotify_id})
      {:ok, playlist_id, spotify_id}
    else
      _ ->
        {:error, :cant_make_playlist}
    end
  end

  def replace_playlist(uris) do
    with [%Playlist{playlist_id: playlist_id} | _] <- SpotifyData.list_playlists(),
         %{snapshot_id: id} <- put(%{uris: uris}, "/v1/playlists/#{playlist_id}/tracks") do
      {:ok, id}
    else
      _ -> {:error, :cant_replace}
    end
  end

  def set_device(id) do
    %{device_ids: [id], play: true}
    |> put("/v1/me/player")
  end

  @spec get_track(String.t()) :: map()
  def get_track(id) do
    get("/v1/tracks/#{id}")
  end

  @spec search(String.t()) :: {:ok, [map()]} | {:error}
  def search(q) do
    query =
      %{
        q: q,
        type: "track",
        market: "GB",
        limit: 10
      }
      |> URI.encode_query()

    case get("/v1/search/?#{query}") do
      %{tracks: %{items: tracks}} ->
        {:ok, tracks}

      _ ->
        {:error}
    end
  end

  @spec client() :: Client.t()
  defp client do
    Client.new(
      strategy: Strategy.AuthCode,
      client_id: get_config(:key),
      client_secret: get_config(:secret),
      redirect_uri: get_config(:redirect_uri),
      grant_type: "authorization_code",
      site: "https://api.spotify.com",
      authorize_url: "https://accounts.spotify.com/authorize",
      token_url: "https://accounts.spotify.com/api/token"
    )
  end

  defp get_config(key) do
    Application.get_env(:pr, :spotify)[key]
  end

  defp get_playlist_name do
    Application.get_env(:pr, :playlist_name)
  end
end
