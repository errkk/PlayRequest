defmodule E.Apis.EndpointHelper do
  defmacro __using__(_) do
    quote do
      require Logger
      alias OAuth2.{Client, Strategy, Response, Error, AccessToken}

      @spec get(String.t()) :: any() | nil
      def get(resource) do
        client()
        |> authenticated_client()
        |> Client.get(resource)
        |> handle_api_response()
      end

      @spec post(String.t(), map()) :: any() | nil
      def post(%{} = params, resource) do
        params = Jason.encode!(params)
        client()
        |> authenticated_client()
        |> Client.post(resource, params)
        |> handle_api_response()
      end

      @spec post(String.t()) :: any() | nil
      def post(resource) do
        client()
        |> authenticated_client()
        |> Client.post(resource)
        |> handle_api_response()
      end

      @spec delete(String.t()) :: any() | nil
      def delete(resource) do
        client()
        |> authenticated_client()
        |> Client.delete(resource)
        |> handle_api_response()
      end

      defp handle_api_response({:ok, %Response{status_code: 200, body: body}}), do: Jason.decode!(body) |> convert_result()
      defp handle_api_response({:error, %Response{status_code: 404, body: body}}), do: Logger.error("Not found")
      defp handle_api_response({:error, %Response{status_code: 401, body: body}}), do: Logger.error("Unauthorized token")
      defp handle_api_response({:error, %Error{reason: reason}}), do: Logger.error("Error: #{inspect reason}")

      @spec authenticated_client(Client.t()) :: Client.t() | {:error, atom()}
      defp authenticated_client(client) do
        case get_access_token() do
          %AccessToken{} = token ->
            client
            |> Map.put(:token, token)
          _ ->
          {:error, :no_token}
        end
      end
    end
  end
end
