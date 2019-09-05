defmodule PR.SpotifyAPI do

  use PR.Apis.TokenHelper
  use PR.Apis.EndpointHelper

  alias OAuth2.{Client, Strategy}

  @tmp_playlist_id "6ebt0TJ6e4CDQVi52gfXt3"

  def get_devices do
    get("/v1/me/player/devices")
  end

  def get_playlists do
    get("/v1/me/playlists")
  end

  def create_playlist do
    %{name: "PlayRequest", public: false}
    |> post("/v1/users/errkkgeorge/playlists")
    |> Map.get(:id)
  end

  def replace_playlist(uris) do
    %{uris: uris}
    |> put("/v1/playlists/#{@tmp_playlist_id}/tracks")
  end

  def set_device(id) do
    %{device_ids: [id], play: true}
    |> put("/v1/me/player")
  end

  @spec get_track(String.t()) :: map()
  def get_track(id) do
    get("/v1/tracks/#{id}")
  end

  @spec search(String.t()) :: {:ok, [map()]} :: {:error}
  def search(q) do
    query = %{
      q: q,
      type: "track",
      market: "GB",
      limit: 10
    }
    |> URI.encode_query()

    case get("/v1/search/?#{query}") do
      %{tracks: %{items: tracks}} ->
        {:ok, tracks}
      _ -> {:error}
    end
  end

  @spec client() :: Client.t()
  defp client do
    Client.new([
      strategy: Strategy.AuthCode,
      client_id: get_config(:key),
      client_secret: get_config(:secret),
      redirect_uri: get_config(:redirect_uri),
      grant_type: "authorization_code",
      site: "https://api.spotify.com",
      authorize_url: "https://accounts.spotify.com/authorize",
      token_url: "https://accounts.spotify.com/api/token"
    ])
  end

  defp get_config(key) do
    Application.get_env(:pr, :spotify)[key]
  end
end

