defmodule PRWeb.UserHeaderView do
  use PRWeb, :view
  import PRWeb.SharedView, only: [heart: 1]

  alias PR.Music.PlaybackState

  def play_pause(_, 0), do: nil

  def play_pause(%PlaybackState{state: :playing}, _num_unplayed) do
    content_tag(:button, "Pause", "phx-click": "toggle_playback", class: "button")
  end

  def play_pause(%PlaybackState{state: :buffering}, _num_unplayed) do
    content_tag(:button, "Play", disabled: true, class: "button loading")
  end

  def play_pause(%PlaybackState{state: :paused}, _num_unplayed) do
    content_tag(:button, "Play", "phx-click": "toggle_playback", class: "button")
  end

  def play_pause(%PlaybackState{state: :idle}, _num_unplayed) do
    content_tag(:button, "Start", "phx-click": "start", class: "button")
  end

  def play_pause(_, _), do: nil
end
