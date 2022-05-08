defmodule PRWeb.PlaybackView do
  use PRWeb, :view

  alias PR.Queue.Track
  alias PR.Music.PlaybackState
  alias PR.Queue.Track
  alias PR.Auth.User

  def playing?(%Track{playing_since: playing}, %PlaybackState{state: :playing})
      when not is_nil(playing),
      do: true

  def playing?(_, _), do: false

  def wobble?(%Track{id: liked_id}, %Track{id: track_id}) when track_id == liked_id,
    do: "track--liked"

  def wobble?(_, _), do: ""

  def progress(%Track{duration: duration} = track, play_state, progress)
      when is_number(progress) do
    if playing?(track, play_state) do
      value = map_range(progress, 0, duration, 0, 100)

      content_tag(:span, class: "progress") do
        content_tag(:span, "", class: "progress__bar", style: "width: #{value}%;")
      end
    end
  end

  def progress(_, _, _), do: nil

  def dun_voted?(%Track{has_pointed: true}), do: true
  def dun_voted?(_), do: false

  def can_vote?(%Track{} = track, %User{} = user),
    do: not it_me?(track, user) and not dun_voted?(track)

  def can_vote?(_, _), do: true

  def it_me?(%Track{user_id: user_id}, %User{id: id}) when id == user_id, do: true
  def it_me?(track, %{assigns: assigns}), do: it_me?(track, assigns)

  def it_me?(%Track{user_id: user_id}, %{current_user: %User{id: current_user_id}})
      when user_id == current_user_id,
      do: true

  def it_me?(_, _), do: false

  def crown(%Track{points_received: nil}, _), do: ""

  def crown(%Track{points_received: points} = track, assigns) when points > 0 do
    if it_me?(track, assigns) do
      content_tag(:div, "👑", class: "crown")
    end
  end

  defp map_range(x, in_min, in_max, out_min, out_max) do
    (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min
  end
end
