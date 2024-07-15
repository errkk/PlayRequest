defmodule PRWeb.LogoSvg do
  use PRWeb, :html

  attr :buffering, :boolean, default: false
  attr :playing, :boolean, default: false
  attr :width, :integer, default: 15

  def logo_svg(assigns) do
    ~H"""
    <svg viewBox="0 0 100 100" class={["logo", variant()]} title={title()}>
      <g transform={transform()}>
        <rect y="15" height="70" class="flag-1" x={x(0)} width={width()} rx="5">
          <.animate_height :if={@playing} begin="0.2s" />
          <.animate_opacity :if={@buffering} begin="0.8s" />
        </rect>
        <rect y="15" height="38" class="flag-2" x={x(1)} width={width()} rx="5">
          <.animate_height :if={@playing} begin="0.4s" />
          <.animate_opacity :if={@buffering} begin="0.7s" />
        </rect>
        <rect y="15" height="60" class="flag-3" x={x(2)} width={width()} rx="5">
          <.animate_height :if={@playing} begin="0.6s" />
          <.animate_opacity :if={@buffering} begin="0.5s" />
        </rect>
        <%= unless is_nil(x(3)) do %>
          <rect y="15" height="45" class="flag-4" x={x(3)} width={width()} rx="5">
            <.animate_height :if={@playing} begin="0.3s" />
            <.animate_opacity :if={@buffering} begin="0s" />
          </rect>
        <% end %>
        <%= unless is_nil(x(4)) do %>
          <rect y="15" height="45" class="flag-5" x={x(4)} width={width()} rx="5">
            <.animate_height :if={@playing} begin="0.1s" />
            <.animate_opacity :if={@buffering} begin="0.1s" />
          </rect>
        <% end %>
      </g>
    </svg>
    """
  end

  def animate_height(assigns) do
    ~H"""
    <animate
      attributeName="height"
      begin={@begin}
      calcMode="spline"
      dur={duration()}
      keySplines="0.5 0 0.5 1;0.5 0 0.5 1;0.5 0 0.5 1"
      keyTimes="0;0.33;0.66;1"
      repeatCount="indefinite"
      values="50;70;30;50"
    />
    """
  end

  def animate_opacity(assigns) do
    ~H"""
    <animate
      attributeName="opacity"
      begin={@begin}
      calcMode="spline"
      dur="2.4"
      keySplines="0.5 0 0.5 1;0.5 0 0.5 1;0.5 0 0.5 1"
      keyTimes="0;0.33;0.66;1"
      opacity="1"
      repeatCount="indefinite"
      values="1;0.1;0.1;1"
    />
    """
  end

  defp x(i) do
    case variant() do
      :pride ->
        [15, 30, 45, 60, 75] |> Enum.at(i)

      :en ->
        [15, 35, 55, 75] |> Enum.at(i)

      _ ->
        [15, 45, 75] |> Enum.at(i)
    end
  end

  defp width() do
    case variant() do
      :pride -> 12
      :en -> 15
      _ -> 25
    end
  end

  defp duration() do
    case variant() do
      :de -> 0.5
      _ -> 1.5
    end
  end

  defp transform() do
    case variant() do
      :en -> "rotate(180 50 50)"
      _ -> "rotate(90 50 50) translate(0, 0)"
    end
  end

  defp title() do
    case variant() do
      :es -> "llegó a casa"
      :de -> "Deutsches Freitag"
      :co -> "martes colombiano"
      :we -> "Welsh Wednesday"
      _ -> nil
    end
  end

  defp variant() do
    Timex.today()
    |> Timex.iso_triplet()
    |> case do
      {2024, 29, _} -> :es
      {_, _, 5} -> :de
      {_, 24, _} -> :pride
      {_, 25, _} -> :pride
      {_, 26, _} -> :pride
      _ -> :en
    end
  end
end
