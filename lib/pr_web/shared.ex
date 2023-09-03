defmodule PRWeb.Shared do
  alias PR.Auth.User

  alias PR.Queue.Track
  alias PR.Auth.User

  def installation_name do
    Application.get_env(:pr, :installation_name, "PlayRequest")
  end

  def is_december? do
    match?(%Date{month: 12}, Date.utc_today())
  end

  def name(%User{first_name: first_name, last_name: nil}) do
    first_name
  end

  def name(%User{first_name: first_name, last_name: last_name}) do
    first_name <> " " <> String.first(last_name)
  end

  def feature_flags() do
    Application.get_env(:pr, :feature_flags)
    |> Map.new(fn {k, v} -> {k, v == "true"} end)
  end

  def it_me?(%Track{user_id: user_id}, %User{id: id}) when id == user_id, do: true
  def it_me?(track, %{assigns: assigns}), do: it_me?(track, assigns)

  def it_me?(%Track{user_id: user_id}, %{current_user: %User{id: current_user_id}})
      when user_id == current_user_id,
      do: true

  def it_me?(_, _), do: false

  def wobble?(%Track{id: liked_id}, %Track{id: track_id}) when track_id == liked_id,
    do: "track--liked"

  def wobble?(_, _), do: ""

  def dun_voted?(%Track{has_pointed: true}), do: true
  def dun_voted?(_), do: false
  def super_liked?(%Track{has_super_liked: true}), do: true
  def super_liked?(_), do: false

  def can_vote?(%Track{} = track, %User{} = user),
    do: not it_me?(track, user) and not dun_voted?(track) and not super_liked?(track)

  def can_vote?(_, _), do: true
end
