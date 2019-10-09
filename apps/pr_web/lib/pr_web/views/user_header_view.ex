defmodule PRWeb.UserHeaderView do
  use PRWeb, :view
  import PRWeb.PlaybackView, only: [heart: 1]

  alias PR.Music.PlaybackState

  def play_pause(%PlaybackState{state: :playing}) do
    content_tag(:button, "Pause", "phx-click": "toggle_playback", class: "button")
  end

  def play_pause(%PlaybackState{state: :buffering}) do
    content_tag(:button, "Play", disabled: true, class: "button loading")
  end

  def play_pause(%PlaybackState{state: :paused}) do
    content_tag(:button, "Play", "phx-click": "toggle_playback", class: "button")
  end

  def play_pause(%PlaybackState{state: :idle}) do
    content_tag(:button, "Start", "phx-click": "start", class: "button")
  end

  def play_pause(_), do: nil
end
