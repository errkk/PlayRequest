defmodule PRWeb.HistoryController do
  use PRWeb, :controller

  alias PR.Queue
  alias PR.Scoring
  alias PR.Auth.User

  def index(conn, _params) do
    items =
      conn
      |> get_user()
      |> Queue.list_todays_tracks()
      |> group_by_hour()

    top_scorers = Scoring.list_top_scorers()

    render(conn, "index.html", items: items, top_scorers: top_scorers)
  end

  defp group_by_hour(items) do
    items
    |> Enum.group_by(fn
      %{played_at: time} -> Timex.format!(time, "{h24}:00")
    end)
  end

  defp get_user(%Plug.Conn{assigns: %{current_user: %User{} = user}}), do: user
  defp get_user(_), do: nil
end
