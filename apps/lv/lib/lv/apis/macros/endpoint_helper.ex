defmodule E.Apis.EndpointHelper do
  defmacro __using__(_) do
    quote do
      require Logger
      alias OAuth2.{Client, Strategy, Response, Error, AccessToken}

      @spec get(String.t()) :: any() | nil
      def get(resource) do
        case client()
          |> authenticated_client()
          |> Client.get(resource)
          |> handle_api_response() do
            {:unauthorized} ->
              get_refresh_token()
              get(resource)
            res -> res
          end
      end

      @spec post(String.t(), map()) :: any() | nil
      def post(%{} = params, resource) do
        params = Jason.encode!(params)
        case client()
          |> authenticated_client()
          |> Client.post(resource, params)
          |> handle_api_response() do
            {:unauthorized} ->
              get_refresh_token()
              post(params, resource)
            res -> res
          end
      end

      @spec post(String.t()) :: any() | nil
      def post(resource) do
        case client()
          |> authenticated_client()
          |> Client.post(resource)
          |> handle_api_response()
            {:unauthorized} ->
              get_refresh_token()
              post(resource)
            res -> res
          end
      end

      @spec put(String.t(), map()) :: any() | nil
      def put(%{} = params, resource) do
        params = Jason.encode!(params)
        case client() do
          |> authenticated_client()
          |> Client.put(resource, params)
          |> handle_api_response() do
            {:unauthorized} ->
              get_refresh_token()
              put(params, resource)
            res -> res
          end
      end

      @spec delete(String.t()) :: any() | nil
      def delete(resource) do
        case client()
          |> authenticated_client()
          |> Client.delete(resource)
          |> handle_api_response() do
            {:unauthorized} ->
              get_refresh_token()
              delete(resource)
            res -> res
          end
      end

      defp handle_api_response({:error, %Response{status_code: 401, body: body}}) do
        Logger.error("Unauthorized token")
        {:unauthorized}
      end
      defp handle_api_response({:ok, %Response{status_code: 200, body: body}}), do: Jason.decode!(body) |> convert_result()
      defp handle_api_response({:ok, %Response{status_code: 204, body: body}}), do: {:ok, nil}
      defp handle_api_response({:error, %Response{status_code: 404, body: body}}), do: Logger.error("Not found")
      defp handle_api_response({:error, %Response{status_code: status_code, body: body}}), do: Logger.error("error: #{status_code}")
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
