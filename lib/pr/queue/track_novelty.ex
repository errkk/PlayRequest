defmodule PR.Queue.TrackNovelty do
  use Ecto.Schema

  schema "track_novelty" do
    field :spotify_id, :string
    field :track_novelty, :integer
  end
end

