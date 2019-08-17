defmodule EWeb.Sonos.SonosWebhookView do
  use EWeb, :view

  def render("index.json", _params) do
    %{status: "success"}
  end
end
