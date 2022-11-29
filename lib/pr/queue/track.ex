defmodule PR.Queue.Track do
  use Ecto.Schema
  import Ecto.Changeset

  alias PR.Auth.User
  alias PR.Scoring.Point

  schema "tracks" do
    field(:artist, :string)
    field(:duration, :integer)
    field(:img, :string)
    field(:spotify_id, :string)
    field(:name, :string)
    field(:played_at, :utc_datetime)
    field(:playing_since, :utc_datetime)

    field(:has_pointed, :boolean, virtual: true)
    field(:points_received, :integer, virtual: true)

    # from a joined view
    field(:artist_novelty, :integer, virtual: true)
    field(:track_novelty, :integer, virtual: true)

    belongs_to(:user, User)
    has_many(:points, Point)

    timestamps()
  end

  @doc false
  def changeset(track, attrs) do
    track
    |> cast(attrs, [
      :name,
      :artist,
      :img,
      :spotify_id,
      :duration,
      :played_at,
      :playing_since,
      :user_id
    ])
    |> validate_required([:name, :artist, :img, :spotify_id, :duration, :user_id])
    |> validate_exclusion(:name, ["World in Motion"])
  end
end
