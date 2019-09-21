defmodule PR.Scoring.Point do
  use Ecto.Schema
  import Ecto.Changeset

  alias PR.Auth.User
  alias PR.Queue.Track

  schema "points" do
    belongs_to :user, User
    belongs_to :track, Track

    timestamps()
  end

  @doc false
  def changeset(point, attrs) do
    point
    |> cast(attrs, [:user_id, :track_id])
    |> validate_required([:user_id, :track_id])
    |> unique_constraint(:track, name: :user_track)
  end
end
