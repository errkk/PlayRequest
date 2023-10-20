defmodule PRWeb.Layouts do
  use PRWeb, :html

  embed_templates("layouts/*")

  def ghost(assigns) do
    halloween = ~D[2023-10-31]

    if Timex.today()
       |> Timex.between?(Timex.beginning_of_week(halloween), Timex.end_of_week(halloween)) do
      ~H"""
      <.ghost_shader />
      """
    else
      ~H"""

      """
    end
  end
end
