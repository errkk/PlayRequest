defmodule PRWeb.PlaybackView do
  use PRWeb, :view

  alias PR.Queue.Track
  alias PR.Music.PlaybackState
  alias PR.Queue.Track
  alias PR.Auth.User

  def playing?(%Track{playing_since: playing}, %PlaybackState{state: :playing}) when not is_nil(playing), do: true
  def playing?(_, _), do: false

  def wobble?(%Track{id: liked_id}, %Track{id: track_id}) when track_id == liked_id, do: "track--liked"
  def wobble?(_, _), do: ""

  def progress(%Track{duration: duration} = track, %PlaybackState{position: position} = play_state) do
    if playing?(track, play_state) do
      value = map_range(position, 0, duration, 0, 100)
      content_tag(:span, class: "progress") do
        content_tag(:span, "", class: "progress__bar", style: "width: #{value}%;")
      end
    end
  end

  def can_vote?(%Track{user_id: user_id}, %User{id: id}) when id == user_id, do: false
  def can_vote?(%Track{has_pointed: true}, _), do: false
  def can_vote?(_, _), do: true

  def heart(%Track{points: points}) when not is_nil(points) do
    1..points
    |> Enum.map(fn _ -> content_tag(:span, "♥️", class: "heart") end)
  end
  def heart(_), do: ""

  defp map_range(x, in_min, in_max, out_min, out_max) do
    (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min
  end
end
