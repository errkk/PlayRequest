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
             |> handle_api_response(resource) do
          {:unauthorized} ->
            get_refresh_token()
            request(resource, method)

          res ->
            res
        end
      end

      @spec request(String.t(), atom(), map() | String.t()) :: any() | nil
      defp request(resource, method, params) do
        params = encode_params(params)

        case client()
             |> authenticated_client()
             |> client_request(resource, method, params)
             |> handle_api_response(resource) do
          {:unauthorized} ->
            get_refresh_token()
            request(resource, method, params)

          res ->
            res
        end
      end

      defp encode_params(%{} = params), do: Jason.encode!(params)
      defp encode_params(params), do: params

      @spec handle_api_response({:error | :ok, Response.t() | Error.t()}, String.t()) ::
              map() | nil
      defp handle_api_response({:error, %Response{status_code: 401}}, _resource) do
        Logger.error("#{__MODULE__}  Code: 401 Unauthorized token")
        {:unauthorized}
      end

      defp handle_api_response(
             {:ok, %Response{status_code: 200, body: body}},
             resource
           ) do
        Logger.info("#{__MODULE__} Code: 200 Resource: #{resource}")

        Jason.decode!(body) |> convert_result()
      end

      defp handle_api_response(
             {:ok, %Response{status_code: 204, body: body}},
             resource
           ) do
        Logger.info("#{__MODULE__} Code: 204 Resource: #{resource}")

        {:ok, nil}
      end

      defp handle_api_response(
             {:ok, %Response{status_code: 201, body: body}},
             resource
           ) do
        Logger.info("#{__MODULE__} Code: 201 Resource: #{resource}")
        Jason.decode!(body) |> convert_result()
      end

      defp handle_api_response({:error, %Response{status_code: 404}}, resource) do
        Logger.error("#{__MODULE__} Code: 404 Resource: #{resource} Not found")
        {:error, :not_found}
      end

      defp handle_api_response({:error, %Response{status_code: 415}}, resource) do
        Logger.error("#{__MODULE__} Code: 415 Resource: #{resource} Unsupported media type")
        {:error, :unsupported_media_type}
      end

      defp handle_api_response({:error, %Response{status_code: 410}}, resource) do
        Logger.error("#{__MODULE__} Code: 410 Resource: #{resource} Gone!")
        {:error, :gone}
      end

      defp handle_api_response({:error, %Response{status_code: 499}}, resource) do
        Logger.error("#{__MODULE__} Code: 499 Resource: #{resource} No content")
        {:error, :no_content}
      end

      defp handle_api_response({:error, %Response{status_code: code, body: body}}, resource) do
        Logger.error(
          "#{__MODULE__} Code: #{code} Resource: #{resource} Response: #{inspect(body)}"
        )

        {:error, body}
      end

      defp handle_api_response({:error, %Error{reason: reason}}, resource) do
        Logger.error("#{__MODULE__} Resource: #{resource} Error reason: #{reason}")
        {:error, reason}
      end

      @spec client_request(Client.t(), String.t(), atom()) :: any() | nil
      defp client_request(client, resource, :get), do: Client.get(client, resource)
      defp client_request(client, resource, :delete), do: Client.delete(client, resource)

      defp client_request(client, resource, :post),
        do:
          client |> Client.put_header("Content-Type", "application/json") |> Client.post(resource)

      defp client_request(client, resource, :put), do: Client.post(client, resource)

      @spec client_request(Client.t(), String.t(), atom(), map()) :: any() | nil
      defp client_request(client, resource, :post, params),
        do:
          client
          |> Client.put_header("Content-Type", "application/json")
          |> Client.post(resource, params)

      defp client_request(client, resource, :put, params),
        do: Client.put(client, resource, params)

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
