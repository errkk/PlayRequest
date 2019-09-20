defmodule PRWeb.PlaybackView do
  use PRWeb, :view

  alias PR.Queue.Track
  alias PR.Music.PlaybackState

  def playing?(%Track{playing_since: playing}, %PlaybackState{state: :playing}) when not is_nil(playing), do: true
  def playing?(_, _), do: false

  def progress(%Track{duration: duration} = track, %PlaybackState{position: position} = play_state) do
    if playing?(track, play_state) do
      value = map_range(position, 0, duration, 0, 100)
      content_tag(:span, class: "progress") do
        content_tag(:span, "", class: "progress__bar", style: "width: #{value}%;")
      end
    end
  end

  defp map_range(x, in_min, in_max, out_min, out_max) do
    (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min
  end
end
