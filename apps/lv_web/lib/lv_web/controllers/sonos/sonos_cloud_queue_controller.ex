defmodule EWeb.Sonos.SonosCloudQueueController do
  use EWeb, :controller

  def context(conn, _params) do
    render(conn, "context.json")
  end

  def item_window(conn, _params) do
    render(conn, "item_window.json")
  end

  def version(conn, _params) do
    render(conn, "version.json")
  end

  def time_played(conn, _params) do
    render(conn, "time_played.json")
  end
end

