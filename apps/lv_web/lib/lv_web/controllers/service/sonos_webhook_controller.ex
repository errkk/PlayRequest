defmodule EWeb.Service.SonosWebhookController do
  use EWeb, :controller

  require Logger
  alias E.PlayState

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

