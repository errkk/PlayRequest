defmodule PRWeb.Service.SonosWebhookController do
  use PRWeb, :controller

  require Logger
  alias PR.PlayState

  def callback(conn, %{"playbackState" => _} = params) do
    params
    |> PlayState.handle_playstate()
    render(conn, "index.json")
  end

  def callback(conn, %{"currentItem" => _} = params) do
    params
    |> PlayState.handle_metadata()
    render(conn, "index.json")
  end

  def callback(conn, %{"container" => _} = params) do
    params
    |> PlayState.handle_metadata()
    render(conn, "index.json")
  end
end

