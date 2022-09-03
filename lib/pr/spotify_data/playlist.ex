defmodule PR.SpotifyData.Playlist do
  use Ecto.Schema
  import Ecto.Changeset

  schema "spotify_playlists" do
    field(:playlist_id, :string)
    field(:spotify_id, :string)

    timestamps()
  end

  @doc false
  def changeset(playlist, attrs) do
    playlist
    |> cast(attrs, [:playlist_id, :spotify_id])
    |> validate_required([:playlist_id, :spotify_id])
  end
end
