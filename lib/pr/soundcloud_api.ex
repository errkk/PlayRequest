defmodule PR.SoundCloudAPI do
  use PR.Apis.TokenHelper
  use PR.Apis.EndpointHelper

  alias OAuth2.{Client, Strategy}

  # SoundCloud uses OAuth 2.1, which requires PKCE on the authorization code
  # flow. The shared TokenHelper auth link/callback do not do PKCE, so those two
  # steps are implemented here (different arities, so they sit alongside the
  # macro-generated ones). The code_verifier is generated when the auth link is
  # built and must be handed back in on the callback.

  @spec get_auth_link!(String.t()) :: String.t()
  def get_auth_link!(code_challenge) do
    client()
    |> Client.put_param(:response_type, "code")
    |> Client.put_param(:state, "xyz")
    |> Client.put_param(:code_challenge, code_challenge)
    |> Client.put_param(:code_challenge_method, "S256")
    |> Client.authorize_url!()
  end

  @spec handle_auth_callback(map(), String.t()) :: {:error, atom()} | {:ok}
  def handle_auth_callback(%{"code" => code}, code_verifier) do
    # SoundCloud's authorization_code endpoint authenticates the client from
    # client_id + client_secret in the request body and ignores the HTTP Basic
    # header the oauth2 AuthCode strategy sends. It only puts client_id in the
    # body, so client_secret has to be added explicitly or it returns
    # invalid_client.
    client()
    |> Client.put_header("accept", "application/json")
    |> Client.get_token(
      code: code,
      code_verifier: code_verifier,
      client_secret: get_config(:secret)
    )
    |> handle_token_response()
  end

  @spec search(String.t()) :: {:ok, [map()]} | {:error}
  def search(q) do
    query = URI.encode_query(%{q: q, limit: 10, access: "playable"})

    case get("/tracks?#{query}") do
      tracks when is_list(tracks) -> {:ok, tracks}
      _ -> {:error}
    end
  end

  @spec get_track(String.t()) :: map() | {:error, term()}
  def get_track(id) do
    get("/tracks/#{id}")
  end

  @spec replace_playlist([String.t()]) :: {:ok, term()} | {:error, term()}
  def replace_playlist(ids) do
    case get_config(:playlist_id) do
      nil ->
        Logger.error("SoundCloud playlist_id not configured")
        {:error, :no_playlist}

      playlist_id ->
        tracks = Enum.map(ids, &%{urn: "soundcloud:tracks:" <> &1})

        case put(%{playlist: %{tracks: tracks}}, "/playlists/#{playlist_id}") do
          %{id: id} ->
            Logger.info("SoundCloud replace playlist success: #{id}")
            {:ok, id}

          err ->
            Logger.error("SoundCloud replace playlist error: #{inspect(err)}")
            {:error, :cant_replace}
        end
    end
  end

  # SoundCloud authenticates the client from client_id + client_secret in the
  # body; the Refresh strategy only sends the Basic header, so add them here.
  def get_refresh_token do
    Logger.info("Refreshing token for #{__MODULE__}")

    refresh_token =
      client()
      |> authenticated_client()
      |> Map.get(:token)
      |> Map.get(:refresh_token)

    client()
    |> Map.put(:strategy, Strategy.Refresh)
    |> Client.put_param(:refresh_token, refresh_token)
    |> Client.put_param(:client_id, get_config(:key))
    |> Client.put_param(:client_secret, get_config(:secret))
    |> Client.put_header("accept", "application/json")
    |> Client.get_token()
    |> handle_refresh_response(refresh_token)
  end

  @spec gen_code_verifier() :: String.t()
  def gen_code_verifier do
    :crypto.strong_rand_bytes(64) |> Base.url_encode64(padding: false)
  end

  @spec code_challenge(String.t()) :: String.t()
  def code_challenge(verifier) do
    :crypto.hash(:sha256, verifier) |> Base.url_encode64(padding: false)
  end

  @spec client() :: Client.t()
  defp client do
    Client.new(
      strategy: Strategy.AuthCode,
      client_id: get_config(:key),
      client_secret: get_config(:secret),
      redirect_uri: get_config(:redirect_uri),
      grant_type: "authorization_code",
      site: "https://api.soundcloud.com",
      authorize_url: "https://secure.soundcloud.com/authorize",
      token_url: "https://secure.soundcloud.com/oauth/token"
    )
  end

  defp get_config(key) do
    Application.get_env(:pr, :soundcloud)[key]
  end
end
