defmodule EWeb.Sonos.SonosWebhookController do
  use EWeb, :controller

  def callback(conn, _params) do
    render(conn, "index.json")
  end
end

