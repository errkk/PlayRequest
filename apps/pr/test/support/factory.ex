defmodule PR.Factory do
  # with Ecto
  use ExMachina.Ecto, repo: PR.Repo


  def user_factory do
    %PR.Auth.User{
      first_name: "Jane",
      last_name: "Jane",
      email: sequence(:email, &"email-#{&1}@gmail.com"),
    }
  end

  def track_factory do
    %PR.Queue.Track{
      name: "Jane",
      artist: "Jane",
      duration: 30000,
      img: "img",
      played_at: nil,
      playing_since: nil,
      user: insert(:user)
    }
  end

  def point_factory do
    %PR.Scoring.Point{
      track: build(:track),
      user: build(:user)
    }
  end
end

