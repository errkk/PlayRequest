defmodule PRWeb.SharedView do
  use Phoenix.HTML
  alias PR.Queue.Track
  alias PRWeb.Router.Helpers, as: Routes

  def heart(points) when is_integer(points) and points > 0 do
    1..points
    |> Enum.map(fn _ ->
      PRWeb.Endpoint
      |> Routes.static_path("/images/heart_pink.svg")
      |> img_tag(class: "heart")
    end)
  end

  def heart(%Track{points_received: points}) when not is_nil(points) do
    heart(points)
  end

  def heart(_), do: ""

  def installation_name do
    Application.get_env(:pr, :installation_name, "PlayRequest")
  end
end
