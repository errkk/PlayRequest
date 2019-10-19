defmodule PRWeb.HistoryView do
  use PRWeb, :view
  import PRWeb.SharedView, only: [heart: 1]

  def time(dt) do
    dt
    |> NaiveDateTime.to_time()
  end

end
