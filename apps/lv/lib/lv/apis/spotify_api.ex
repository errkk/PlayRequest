defmodule E.SpotifyAPI do

  use E.ExternalAuth.TokenHelper
  use E.ExternalAuth.EndpointHelper

  alias OAuth2.{Client, Strategy}

  def get_devices do
    client()
    |> get("/v1/me/player/devices")
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
    Application.get_env(:lv, :spotify)[key]
  end
end

