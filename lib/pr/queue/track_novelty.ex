defmodule PR.Queue.TrackNovelty do
  use Ecto.Schema

  @primary_key false
  schema "track_novelty" do
    field(:external_id, :string)
    field(:provider, :string)
    field(:track_novelty, :integer)
  end
end
