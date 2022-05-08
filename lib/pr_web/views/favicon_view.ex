defmodule PRWeb.FaviconView do
  use PRWeb, :view

  alias PR.Music.PlaybackState

  def playback_canvas(%PlaybackState{state: :playing}), do: canvas(:active)
  def playback_canvas(_), do: canvas(:inactive)

  defp canvas(state) do
    content_tag(:span, "", id: "play_state", data: [playback: state])
  end
end
