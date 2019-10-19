defmodule PRWeb.SharedView do
  use PRWeb, :view

  alias PR.Queue.Track

  def heart(points) when is_integer(points) and points > 0 do
    1..points
    |> Enum.map(fn _ -> content_tag(:span, "♥️", class: "heart") end)
  end
  def heart(%Track{points_received: points}) when not is_nil(points) do
    heart(points)
  end
  def heart(_), do: ""

end

