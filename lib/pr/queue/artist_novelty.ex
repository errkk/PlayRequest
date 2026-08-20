defmodule PR.Queue.ArtistNovelty do
  use Ecto.Schema

  @primary_key false
  schema "artist_novelty" do
    field(:artist, :string)
    field(:artist_novelty, :integer)
  end
end
