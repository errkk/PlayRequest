defmodule PRWeb.Layouts do
  use PRWeb, :html

  embed_templates("layouts/*")

  def ghost(assigns) do
    if same_week?(Timex.today(), ~D[2025-10-31]) do
      ~H"""
      <.ghost_shader />
      """
    else
      ~H"""

      """
    end
  end

  defp same_week?(date1, date2) do
    {_year1, week1, _weekday} = Timex.iso_triplet(date1)
    {_year2, week2, _weekday} = Timex.iso_triplet(date2)

    week1 == week2
  end
end
