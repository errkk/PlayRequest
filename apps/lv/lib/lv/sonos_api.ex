defmodule E.SonosAPI do

  @sonos Application.get_env(:lv, :sonos)

  require Logger
  alias OAuth2.{Client, Strategy, Response, Error}

  #@spec get(String.t()) :: any() | nil
  #def get(resource) do
    #case Client.get(client, resource) do
      #{:ok, %Response{body: body}} ->
        #body
      #{:error, %Response{status_code: 401, body: body}} ->
        #Logger.error("Unauthorized token")
      #{:error, %Error{reason: reason}} ->
        #Logger.error("Error: #{inspect reason}")
    #end
  #end

  @doc "Get OAuth URL to authorise with sonos"
  def get_auth_link! do
    get_client()
    |> Client.put_param(:state, "xyz")
    |> Client.authorize_url!()
  end

  def handle_auth_callback!(%{"code" => code, "state" => state}) do
    get_client()
    |> Client.put_header("accept", "application/json")
    |> Client.get_token(code: code)
    |> IO.inspect

    # Save the token somewhere
  end

  def handle_auth_callback!(%{"access_token": access_token, "refresh_token": refresh_token}) do
    IO.puts "no code sent back"
  end

  @spec get_token!(String.t()) :: Client.t()
  defp get_token!(code) do
    Client.get_token!(
      get_client(),
      code: code,
      redirect_uri: @sonos[:redirect_uri])
  end

  defp get_client do
    Client.new([
      strategy: Strategy.AuthCode,
      client_id: @sonos[:key],
      client_secret: @sonos[:secret],
      redirect_uri: @sonos[:redirect_uri],
      grant_type: "authorization_code",
      site: "https://api.sonos.com",
      authorize_url: "/login/v3/oauth",
      token_url: "/login/v3/oauth/access"
    ])
  end
end
