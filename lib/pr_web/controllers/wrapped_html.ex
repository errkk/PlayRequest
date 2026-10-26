defmodule PRWeb.WrappedHTML do
  use PRWeb, :html

  embed_templates "wrapped_html/*"

  @days ~w(Mon Tue Wed Thu Fri)
  @hours 8..18

  def days, do: Enum.with_index(@days, 1)
  def hours, do: @hours

  def heat(heatmap, dow, hour) do
    max = heatmap |> Enum.map(& &1.n) |> Enum.max(fn -> 1 end)

    case Enum.find(heatmap, &(&1.dow == dow and &1.hour == hour)) do
      nil -> 0
      %{n: n} -> Float.round(n / max, 2)
    end
  end

  def change(_now, %{tracks: 0}), do: nil

  def change(%{tracks: now}, %{tracks: before}) do
    pct = round((now - before) / before * 100)
    if pct >= 0, do: "+#{pct}%", else: "#{pct}%"
  end

  def number(n) when n >= 1000, do: "#{div(n, 1000)},#{n |> rem(1000) |> pad()}"
  def number(n), do: "#{n}"

  defp pad(n), do: n |> Integer.to_string() |> String.pad_leading(3, "0")

  def duration(ms) do
    mins = div(ms, 60_000)
    "#{div(mins, 60)}h #{rem(mins, 60)}m"
  end

  def day(date), do: Calendar.strftime(date, "%A %-d %B")

  def bucket(1), do: "Just one of you"
  def bucket(2), do: "2-3 people"
  def bucket(3), do: "4-6 people"
  def bucket(4), do: "7 or more"

  def love_per_track(%{queued: 0}), do: 0
  def love_per_track(%{queued: q, love_rx: l}), do: Float.round(l / q, 2)

  def top_by(people, fun, min_queued \\ 0) do
    people
    |> Enum.filter(&(&1.queued >= min_queued))
    |> Enum.sort_by(fun, :desc)
    |> Enum.take(5)
  end

  def generous(people) do
    people
    |> Enum.filter(&(&1.love_rx > 0 and &1.given >= 20))
    |> Enum.sort_by(&(&1.given / &1.love_rx), :desc)
    |> Enum.take(3)
  end

  def explorers(people, dir) do
    people
    |> Enum.filter(&(&1.queued >= 50 and &1.pct_new))
    |> Enum.sort_by(& &1.pct_new, dir)
    |> Enum.take(3)
  end

  attr :src, :string, required: true

  def avatar(assigns) do
    ~H"""
    <img src={@src} class="wrapped__avatar" referrerpolicy="no-referrer" />
    """
  end
end
