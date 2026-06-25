defmodule PR.Apis.TokenHelper do
  @doc """
  True when an OAuth token response body reports an `invalid_grant` error.

  Spotify returns this when a refresh token has expired (six month lifetime
  from July 20, 2026). The body may be a decoded map or a raw JSON string
  depending on the configured serializer.
  """
  @spec invalid_grant?(any()) :: boolean()
  def invalid_grant?(%{"error" => "invalid_grant"}), do: true
  def invalid_grant?(body) when is_binary(body), do: String.contains?(body, "invalid_grant")
  def invalid_grant?(_), do: false

  defmacro __using__(_) do
    quote do
      require Logger
      use Agent
      alias OAuth2.{Client, Strategy, Response, Error, AccessToken}
      alias PR.ExternalAuth
      alias PR.ExternalAuth.Auth

      @doc "Get OAuth URL to authorise with sonos"
      def get_auth_link! do
        client()
        |> Client.put_param(:state, "xyz")
        |> Client.put_param(:scope, scopes())
        |> Client.authorize_url!()
      end

      @spec handle_auth_callback(map()) :: {:error, atom()} | {:ok}
      def handle_auth_callback(%{"code" => code}) do
        client()
        |> Client.put_header("accept", "application/json")
        |> Client.get_token(code: code)
        |> handle_token_response()
      end

      @spec handle_token_response({:error, any()} | {:ok, Client.t()}) :: {:error, atom()} | {:ok}
      defp handle_token_response({:ok, client}) do
        try do
          client
          |> Map.get(:token)
          |> Map.get(:access_token)
          |> Jason.decode!()
        rescue
          _ ->
            {:error, :other}
        else
          params ->
            params
            |> Map.put("activated_at", DateTime.utc_now())
            |> Map.put("service", Atom.to_string(__MODULE__))
            |> ExternalAuth.insert_or_update_auth()

            Logger.info("Saving refresh token for #{__MODULE__}")
            cache_stored_credential()
            {:ok}
        end
      end

      defp handle_token_response({:error, _}) do
        {:error, :auth}
      end

      def handle_auth_callback!(_) do
        {:error, :other}
      end

      def start_link(_) do
        Agent.start_link(fn -> nil end, name: __MODULE__)
      end

      @spec get_access_token() :: AccessToken.t() | {:error, atom()}
      defp get_access_token do
        case Agent.get(__MODULE__, & &1) do
          %AccessToken{} = token ->
            Logger.debug("Getting token from cache")
            token

          _ ->
            Logger.debug("Getting token from DB")
            cache_stored_credential()
        end
      end

      @spec put_access_token(AccessToken.t()) :: AccessToken.t()
      defp put_access_token(data) do
        Logger.debug("Writing token to Agent")
        Agent.update(__MODULE__, fn _state -> data end)
        data
      end

      @spec cache_stored_credential() :: AccessToken.t() | {:error, atom()}
      defp cache_stored_credential do
        case get_token_from_database() do
          %AccessToken{} = token -> put_access_token(token)
          err -> err
        end
      end

      @spec get_token_from_database() :: AccessToken.t() | {:error, atom()}
      defp get_token_from_database do
        case ExternalAuth.get_auth(__MODULE__) do
          %Auth{} = auth ->
            Auth.to_token(auth)

          _ ->
            {:error, :no_token}
        end
      end

      @spec get_token!(String.t()) :: Client.t()
      defp get_token!(code) do
        Client.get_token!(
          client(),
          code: code,
          redirect_uri: get_config(:redirect_uri)
        )
      end

      @spec get_refresh_token() :: {:error, atom()} | {:ok}
      def get_refresh_token() do
        Logger.info("Refreshing token for #{__MODULE__}")

        refresh_token =
          client()
          |> authenticated_client()
          |> Map.get(:token)
          |> Map.get(:refresh_token)

        client()
        |> Map.put(:strategy, Strategy.Refresh)
        |> Client.put_param(:refresh_token, refresh_token)
        |> Client.put_header("accept", "application/json")
        |> Client.get_token()
        |> handle_refresh_response()
      end

      @spec handle_refresh_response({:error, any()} | {:ok, Client.t()}) ::
              {:error, atom()} | {:ok}
      defp handle_refresh_response({:error, %Response{body: body}} = response) do
        if PR.Apis.TokenHelper.invalid_grant?(body) do
          Logger.warning("Refresh token expired for #{__MODULE__}, discarding. Reauth required.")
          discard_token()
          {:error, :invalid_grant}
        else
          handle_token_response(response)
        end
      end

      defp handle_refresh_response(response) do
        handle_token_response(response)
      end

      @spec discard_token() :: :ok
      defp discard_token do
        ExternalAuth.discard_auth(__MODULE__)
        Agent.update(__MODULE__, fn _state -> nil end)
        :ok
      end

      @spec scopes() :: String.t()
      defp scopes do
        case get_config(:scopes) do
          scopes when is_list(scopes) ->
            Enum.join(scopes, ",")

          scopes ->
            scopes
        end
      end

      @spec convert_result(map()) :: map()
      def convert_result(result) do
        result
        |> Map.Helpers.underscore_keys()
        |> Map.Helpers.atomize_keys()
      end

      # SoundCloud needs client credentials in the refresh body, not just the
      # Basic header the Refresh strategy sends, so it overrides this.
      defoverridable get_refresh_token: 0
    end
  end
end
