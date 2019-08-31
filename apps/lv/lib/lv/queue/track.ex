defmodule E.Queue.Track do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tracks" do
    field :artist, :string
    field :duration, :integer
    field :img, :string
    field :spotify_id, :string
    field :name, :string
    field :played_at, :utc_datetime

    timestamps()
  end

  @doc false
  def changeset(track, attrs) do
    track
    |> cast(attrs, [:name, :artist, :img, :spotify_id, :duration, :played_at])
    |> validate_required([:name, :artist, :img, :spotify_id, :duration])
  end
end
