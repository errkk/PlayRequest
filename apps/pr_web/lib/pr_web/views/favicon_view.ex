defmodule PRWeb.FaviconView do
  use PRWeb, :view

  alias PR.Music.PlaybackState

  def playback_canvas(%PlaybackState{state: :playing}), do: canvas(:active)
  def playback_canvas(_), do: canvas(:inactive)

  defp canvas(state) do
    tag(:canvas, id: "canvas", width: "32px", height: "32px", data: [playback: state])
  end
end
