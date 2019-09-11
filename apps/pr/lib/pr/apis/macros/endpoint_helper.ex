defmodule PR.Apis.EndpointHelper do
  defmacro __using__(_) do
    quote do
      require Logger
      alias OAuth2.{Client, Strategy, Response, Error, AccessToken}

      @spec get(String.t()) :: any() | nil
      def get(resource) do
        request(resource, :get)
      end

      @spec post(map(), String.t()) :: any() | nil
      def post(%{} = params, resource) do
        request(resource, :post, params)
      end

      @spec post(String.t()) :: any() | nil
      def post(resource) do
        request(resource, :post)
      end

      @spec put(map(), String.t()) :: any() | nil
      def put(%{} = params, resource) do
        request(resource, :put, params)
      end

      @spec delete(String.t()) :: any() | nil
      def delete(resource) do
        request(resource, :delete)
      end

      @spec request(String.t(), atom()) :: any() | nil
      defp request(resource, method) do
        case client()
          |> authenticated_client()
          |> client_request(resource, method)
          |> handle_api_response() do
            {:unauthorized} ->
              get_refresh_token()
              request(resource, method)
            res -> res
          end
      end

      @spec request(String.t(), atom(), map() | String.t()) :: any() | nil
      defp request(resource, method, params) do
        params = encode_params(params)

        case client()
          |> authenticated_client()
          |> client_request(resource, method, params)
          |> handle_api_response() do
            {:unauthorized} ->
              get_refresh_token()
              request(resource, method, params)
            res -> res
          end
      end

      defp encode_params(%{} = params), do: Jason.encode!(params)
      defp encode_params(params), do: params


      @spec handle_api_response({:error | :ok, Response.t() | Error.t()}) :: map() | nil
      defp handle_api_response({:error, %Response{status_code: 401, body: body}}) do
        Logger.error("Unauthorized token")
        {:unauthorized}
      end
      defp handle_api_response({:ok, %Response{status_code: 200, body: body}}), do: Jason.decode!(body) |> convert_result()
      defp handle_api_response({:ok, %Response{status_code: 204, body: body}}), do: {:ok, nil}
      defp handle_api_response({:ok, %Response{status_code: 201, body: body}}), do: Jason.decode!(body) |> convert_result()
      defp handle_api_response({:error, %Response{status_code: 404, body: body}}), do: Logger.error("Not found")
      defp handle_api_response({:error, %Response{status_code: 401, body: body}}), do: Logger.error("Gone")
      defp handle_api_response({:error, %Response{status_code: status_code, body: body}}), do: Logger.error("error: #{status_code}")
      defp handle_api_response({:error, %Error{reason: reason}}), do: Logger.error("Error: #{inspect reason}")


      @spec client_request(Client.t(), String.t(), atom()) :: any() | nil
      defp client_request(client, resource, :get), do: Client.get(client, resource)
      defp client_request(client, resource, :delete), do: Client.delete(client, resource)
      defp client_request(client, resource, :post), do: Client.post(client, resource)
      defp client_request(client, resource, :put), do: Client.post(client, resource)

      @spec client_request(Client.t(), String.t(), atom(), map()) :: any() | nil
      defp client_request(client, resource, :post, params), do: Client.post(client, resource, params)
      defp client_request(client, resource, :put, params), do: Client.put(client, resource, params)


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
