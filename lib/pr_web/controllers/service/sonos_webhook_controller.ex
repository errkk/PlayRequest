defmodule PRWeb.Service.SonosWebhookController do
  use PRWeb, :controller

  require Logger
  alias PR.PlayState

  def callback(conn, %{"playbackState" => _} = params) do
    case get_req_header(conn, "x-sonos-target-value") do
      [group_id | _tail] ->
        PlayState.handle_play_state_webhook(params, group_id, request_id())
        render(conn, "index.json")
      _ ->
        Logger.error("PlaybackState webhook, no group id provided")
        render(conn, "index.json")
    end
  end

  def callback(conn, %{"currentItem" => _} = params) do
    case get_req_header(conn, "x-sonos-target-value") do
      [group_id | _tail] ->
        PlayState.handle_metadata_webhook(params, group_id, request_id())
        render(conn, "index.json")
      _ ->
        Logger.error("Metadata webhook, no group id provided")
        render(conn, "index.json")
    end
  end

  def callback(conn, %{"errorCode" => _} = params) do
    case get_req_header(conn, "x-sonos-target-value") do
      [group_id | _tail] ->
        PlayState.handle_error_webhook(params, group_id, request_id())
        render(conn, "index.json")
      _ ->
        Logger.error("Error webhook, no group id provided")
        render(conn, "index.json")
    end
  end

  def callback(conn, params) do
    {:ok, json} = Jason.encode(params)
    Logger.error("Other webhook: #{json}")
    render(conn, "index.json")
  end

  defp request_id do
    Logger.metadata()
    |> Keyword.get(:request_id)
  end
end

