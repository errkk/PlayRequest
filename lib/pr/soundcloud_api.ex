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
    client()
    |> Client.put_header("accept", "application/json")
    |> Client.get_token(code: code, code_verifier: code_verifier)
    |> handle_token_response()
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
