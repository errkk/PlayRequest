defmodule PRWeb.HistoryHTML do
  use PRWeb, :html

  import PRWeb.PlaybackComponents

  embed_templates "history_html/*"

  def time(dt) do
    dt
    |> Timex.Timezone.convert(tz())
    |> Timex.format!("{h24}:{m}")
  end

  defp tz do
    Application.get_env(:pr, :timezone)
  end
  
end
