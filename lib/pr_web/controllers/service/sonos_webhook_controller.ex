defmodule PRWeb.Service.SonosWebhookController do
  use PRWeb, :controller

  require Logger
  alias PR.PlayState

  def callback(conn, %{"playbackState" => _} = params) do
    Logger.info("Playback state webhook")
    params
    |> PlayState.handle_play_state_webhook()
    render(conn, "index.json")
  end

  def callback(conn, %{"currentItem" => _} = params) do
    Logger.info("Metadata webhook")
    params
    |> PlayState.handle_metadata_webhook()

    render(conn, "index.json")
  end

  def callback(conn, _params) do
    Logger.info("Other webhook")
    render(conn, "index.json")
  end
end

