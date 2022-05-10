defmodule PR.Queue.TrackScore do
  use Ecto.Schema

  alias PR.Queue.Track

  schema "track_scores" do
    field :spotify_id, :string
    field :track_score, :decimal
    field :artist_score, :decimal
    field :score, :decimal

    belongs_to :track, Track
  end
end

