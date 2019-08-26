defmodule E.SonosAPI do

  use E.ExternalAuth.TokenHelper
  use E.ExternalAuth.EndpointHelper

  alias OAuth2.{Client, Strategy}

  def get_households do
    client()
    |> Client.put_header("X-Sonos-Api-Key", get_config(:key))
    |> get("/households")
  end

  @spec client() :: Client.t()
  defp client do
    Client.new([
      strategy: Strategy.AuthCode,
      client_id: get_config(:key),
      client_secret: get_config(:secret),
      redirect_uri: get_config(:redirect_uri),
      grant_type: "authorization_code",
      site: "https://api.ws.sonos.com/control/api/v1",
      authorize_url: "https://api.sonos.com/login/v3/oauth",
      token_url: "https://api.sonos.com/login/v3/oauth/access"
    ])
  end

  defp get_config(key) do
    Application.get_env(:lv, :sonos)[key]
  end
end

