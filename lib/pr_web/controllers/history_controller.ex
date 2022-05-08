defmodule PRWeb.HistoryController do
  use PRWeb, :controller

  alias PR.Queue
  alias PR.Scoring
  alias PR.Auth.User
  alias PR.Queue
  alias PR.Queue.Track

  def index(conn, _params) do
    items =
      conn
      |> get_user()
      |> Queue.list_todays_tracks()
      |> group_by_hour()

    top_scorers = Scoring.list_top_scorers()

    render(conn, "index.html", items: items, top_scorers: top_scorers)
  end

  def mark_unplayed(conn, %{"id" => id}) do
    id
    |> Queue.get_track!()
    |> Queue.mark_unplayed()
    |> case do
      {:ok, %Track{name: name}} ->
        conn
        |> put_flash(:info, "😅 Sarry bout dat. Giving '#{name}' another try")
        |> redirect(to: "/")
      _ ->
        conn
        |> put_flash(:error, "⚠️ Didn't work")
        |> redirect(to: Routes.history_path(conn, :index))
    end
  end

  def mark_unplayed(conn, _) do
    conn
    |> put_flash(:error, "⚠️ Didn't work")
    |> redirect(to: Routes.history_path(conn, :index))
  end

  defp group_by_hour(items) do
    items
    |> Enum.group_by(fn
      %{played_at: dt} ->
        dt
        |> Timex.Timezone.convert(tz())
        |> Timex.format!("{h24}:00")
    end)
  end

  defp get_user(%Plug.Conn{assigns: %{current_user: %User{} = user}}), do: user
  defp get_user(_), do: nil

  defp tz do
    Application.get_env(:pr, :timezone)
  end
end

