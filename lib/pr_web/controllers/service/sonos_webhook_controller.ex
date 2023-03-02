defmodule PRWeb.Service.SonosWebhookController do
  use PRWeb, :controller

  require Logger
  alias PR.PlayState

  def callback(conn, %{"playbackState" => _} = params) do
    case get_req_header(conn, "x-sonos-target-value") do
      [group_id | _tail] ->
        PlayState.handle_play_state_webhook(params, group_id, request_id())
        send_resp(conn, 202, "")

      _ ->
        Logger.error("PlaybackState webhook, no group id provided")
        send_resp(conn, 202, "")
    end
  end

  def callback(conn, %{"currentItem" => _} = params) do
    case get_req_header(conn, "x-sonos-target-value") do
      [group_id | _tail] ->
        PlayState.handle_metadata_webhook(params, group_id, request_id())
        send_resp(conn, 202, "")

      _ ->
        Logger.error("Metadata webhook, no group id provided")
        send_resp(conn, 202, "")
    end
  end

  def callback(conn, %{"errorCode" => _} = params) do
    case get_req_header(conn, "x-sonos-target-value") do
      [group_id | _tail] ->
        PlayState.handle_error_webhook(params, group_id, request_id())
        send_resp(conn, 202, "")

      _ ->
        Logger.error("Error webhook, no group id provided")
        send_resp(conn, 202, "")
    end
  end

  def callback(conn, %{"container" => %{"name" => name}}) do
    Logger.warn("Ignoring metadata playing #{name}")
    send_resp(conn, 202, "")
  end

  def callback(conn, %{"groupStatus" => _} = params) do
    case get_req_header(conn, "x-sonos-target-value") do
      [group_id | _tail] ->
        PlayState.handle_group_status_webhook(params, group_id, request_id())
        send_resp(conn, 202, "")

      _ ->
        Logger.error("Group status webhook, no group id provided")
        send_resp(conn, 202, "")
    end
  end

  def callback(conn, params) do
    {:ok, json} = Jason.encode(params)
    Logger.error("Other webhook: #{json}")
    send_resp(conn, 202, "")
  end

  defp request_id do
    Logger.metadata()
    |> Keyword.get(:request_id)
  end
end
