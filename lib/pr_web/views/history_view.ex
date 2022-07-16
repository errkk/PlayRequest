defmodule PRWeb.HistoryView do
  use PRWeb, :view

  def time(dt) do
    dt
    |> Timex.Timezone.convert(tz())
    |> Timex.format!("{h24}:{m}")
  end

  defp tz do
    Application.get_env(:pr, :timezone)
  end
end
