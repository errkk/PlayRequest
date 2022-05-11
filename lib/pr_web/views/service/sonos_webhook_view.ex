defmodule PRWeb.Service.SonosWebhookView do
  use PRWeb, :view

  def render("index.json", _params) do
    %{status: "success"}
  end
end
