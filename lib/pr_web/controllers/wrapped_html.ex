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

  # 0.15..1 so the smallest arrow is still visible
  def weight(_, 0), do: 0.15
  def weight(n, max), do: Float.round(0.15 + 0.85 * n / max, 2)

  attr :name, :string, required: true
  attr :image, :string, required: true

  def person(assigns) do
    ~H"""
    <div class="wrapped__person">
      <.avatar src={@image} />
      <span>{@name}</span>
    </div>
    """
  end

  attr :count, :integer, required: true
  attr :max, :integer, required: true
  attr :back, :boolean, default: false

  def arrow(assigns) do
    ~H"""
    <div
      class={["wrapped__arrow", @back && "wrapped__arrow--back"]}
      style={"--w: #{weight(@count, @max)}"}
    >
      <span class="wrapped__arrow-count">
        <img src={~p"/images/heart_pink.svg"} />
        {@count}
      </span>
      <span class="wrapped__arrow-line"></span>
    </div>
    """
  end

  @doc "Giver -> receiver, arrow and heart sized by likes. both: also draw likes returned"
  attr :pair, :map, required: true
  attr :max, :integer, required: true
  attr :both, :boolean, default: false

  def flow(assigns) do
    ~H"""
    <div class="wrapped__flow">
      <.person name={@pair.giver} image={@pair.giver_image} />
      <div class="wrapped__arrows">
        <.arrow count={@pair.likes} max={@max} />
        <.arrow :if={@both} count={@pair.returned} max={@max} back />
      </div>
      <.person name={@pair.receiver} image={@pair.receiver_image} />
    </div>
    """
  end

  attr :twins, :map, required: true

  def twins(assigns) do
    ~H"""
    <div class="wrapped__flow">
      <.person name={@twins.a} image={@twins.a_image} />
      <div class="wrapped__venn">
        <div class="wrapped__venn-circles">
          <span></span>
          <span></span>
          <strong>{@twins.shared}</strong>
        </div>
        <small>artists in common</small>
      </div>
      <.person name={@twins.b} image={@twins.b_image} />
    </div>
    """
  end
end
