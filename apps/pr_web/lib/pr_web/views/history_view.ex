defmodule PRWeb.HistoryView do
  use PRWeb, :view
  import PRWeb.SharedView, only: [heart: 1]

  def time(dt) do
    dt
    |> Timex.Timezone.convert(tz())
    |> Timex.format!("{h24}:{m}")
  end

  defp tz do
    Application.get_env(:pr, :timezone)
  end
end
