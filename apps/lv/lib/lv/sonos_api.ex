defmodule E.SonosAPI do

  @sonos Application.get_env(:lv, :sonos)

  require Logger
  alias OAuth2.{Client, Strategy, Response, Error, AccessToken}
  alias E.Sonos

  @household_id "Sonos_tzRfiKzs5k7zdAz15qxl6JGuqY.NP8UdSZBTkrhfgUAv3wC"
  @group_id "RINCON_B8E9378F13B001400:2815415479"

  def get_households do
    get("/households")
  end

  def get_groups do
    get("/households/#{@household_id}/groups")
  end

  def subscribe_playback do
    post("/groups/#{@group_id}/playback/subscription")
  end

  def get_playback do
    get("/groups/#{@group_id}/playback")
  end

  def subscribe_metadata do
    post("/groups/#{@group_id}/playbackMetadata/subscription")
  end

  def get_metadata do
    get("/groups/#{@group_id}/playbackMetadata")
  end

  def toggle_playback do
    post("/groups/#{@group_id}/playback/togglePlayPause")
  end

  @spec get(String.t()) :: any() | nil
  defp get(resource) do
    get_stored_credentials()
    |> Client.get(resource)
    |> handle_api_response()
  end

  @spec post(String.t()) :: any() | nil
  defp post(resource) do
    get_stored_credentials()
    |> Client.post(resource)
    |> handle_api_response()
  end

  @spec delete(String.t()) :: any() | nil
  defp delete(resource) do
    get_stored_credentials()
    |> Client.delete(resource)
    |> handle_api_response()
  end

  defp handle_api_response({:ok, %Response{status_code: 200, body: body}}), do: Jason.decode!(body) |> convert_result()
  defp handle_api_response({:error, %Response{status_code: 404, body: body}}), do: Logger.error("Not found")
  defp handle_api_response({:error, %Response{status_code: 401, body: body}}), do: Logger.error("Unauthorized token")
  defp handle_api_response({:error, %Error{reason: reason}}), do: Logger.error("Error: #{inspect reason}")

  @spec get_stored_credentials() :: Client.t() :: {:error, atom()}
  defp get_stored_credentials do
    case Sonos.get_auth() do
      %{access_token: _, refresh_token: _} = params ->
        params
        |> Map.take([:access_token, :refresh_token])
        |> Map.Helpers.stringify_keys()
        |> AccessToken.new()
        |> get_api_client()
      _ ->
      {:error, :no_token}
    end
  end

  @doc "Get OAuth URL to authorise with sonos"
  def get_auth_link! do
    get_auth_client()
    |> Client.put_param(:state, "xyz")
    |> Client.put_param(:scope, "playback-control-all")
    |> Client.authorize_url!()
  end

  @spec handle_auth_callback(map()) :: {:error, atom()} | {:ok}
  def handle_auth_callback(%{"code" => code, "state" => state}) do
    try do
      get_auth_client()
        |> Client.put_header("accept", "application/json")
        |> Client.get_token!(code: code)
        |> Map.get(:token)
        |> Map.get(:access_token)
        |> Jason.decode!()
    rescue
      Error ->
        {:error, :auth}
      _ ->
        {:error, :other}
    else
      params ->
        params
        |> Map.put("activated_at", DateTime.utc_now())
        |> Sonos.create_auth()
      {:ok}
    end
  end

  def handle_auth_callback!(_) do
    {:error, :other}
  end

  @spec get_token!(String.t()) :: Client.t()
  defp get_token!(code) do
    Client.get_token!(
      get_auth_client(),
      code: code,
      redirect_uri: @sonos[:redirect_uri])
  end

  @spec get_auth_client() :: Client.t()
  defp get_auth_client do
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

  @spec get_api_client(AccessToken.t()) :: Client.t()
  defp get_api_client(token) do
    Client.new([
      client_id: @sonos[:key],
      client_secret: @sonos[:secret],
      site: "https://api.ws.sonos.com/control/api/v1",
      token: token,
    ])
    |> Client.put_header("X-Sonos-Api-Key", @sonos[:key])
  end

  @spec convert_result(map()) :: map()
  def convert_result(result) do
    result
    |> Map.Helpers.underscore_keys()
    |> Map.Helpers.atomize_keys()
  end
end
