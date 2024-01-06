defmodule PRWeb.LogoSvg do
  use PRWeb, :html

  attr :buffering, :boolean, default: false
  attr :playing, :boolean, default: false
  attr :width, :integer, default: 15

  def logo_svg(assigns) do
    ~H"""
    <svg viewBox="0 0 100 100" class={["logo", variant()]}>
      <g transform="rotate(180 50 50)">
        <rect y="15" height="69.3246" class="flag-1" x={x(0)} width={width()} rx="5">
          <.animate_height :if={@playing} begin="0.2s" />
          <.animate_opacity :if={@buffering} begin="0.8s" />
        </rect>
        <rect y="15" height="51.9636" class="flag-2" x={x(1)} width={width()} rx="5">
          <.animate_height :if={@playing} begin="0.4s" />
          <.animate_opacity :if={@buffering} begin="0.3s" />
        </rect>
        <rect y="15" height="53.5006" class="flag-3" x={x(2)} width={width()} rx="5">
          <.animate_height :if={@playing} begin="0.6s" />
          <.animate_opacity :if={@buffering} begin="0.5s" />
        </rect>
        <%= unless is_nil(x(3)) do %>
          <rect y="15" height="45.4203" class="flag-1" x={x(3)} width={width()} rx="5">
            <.animate_height :if={@playing} begin="0.8s" />
            <.animate_opacity :if={@buffering} begin="0s" />
          </rect>
        <% end %>
      </g>
    </svg>
    """
  end

  defp x(i) do
    case variant() do
      :en ->
        [15, 35, 55, 75] |> Enum.at(i)

      _ ->
        [15, 45, 75] |> Enum.at(i)
    end
  end

  defp width() do
    case variant() do
      :en -> 15
      _ -> 25
    end
  end

  defp variant() do
    Timex.today()
    |> Timex.weekday()
    |> case do
      5 -> :de
      2 -> :co
      _ -> :en
    end
  end

  def animate_height(assigns) do
    ~H"""
    <animate
      attributeName="height"
      begin={@begin}
      calcMode="spline"
      dur="1.4"
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
end
