defmodule PR.Scoring.Point do
  use Ecto.Schema
  import Ecto.Changeset

  alias PR.Auth.User
  alias PR.Queue
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
    |> validate_vote_fraud()
  end

  def validate_vote_fraud(changeset) do
    user_id = get_change(changeset, :user_id)
    case changeset
    |> get_change(:track_id)
    |> Queue.get_track() do
      %Track{user_id: ^user_id} ->
        add_error(changeset, :user_id, "oh_no_you_dont")
      _ ->
        changeset
    end
  end
end
