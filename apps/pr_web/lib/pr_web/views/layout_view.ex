defmodule PRWeb.LayoutView do
  use PRWeb, :view

  def is_snow_season? do
    {:ok, from} =
      Date.utc_today()
      |> Map.get(:year)
      |> Date.new(12, 1)

    to =
      from
      |> Map.put(:day, 26)

    Date.utc_today |> Timex.between?(from, to)
  end
end
