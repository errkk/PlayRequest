defmodule PR.Repo.Migrations.CreateSpotifyPlaylists do
  use Ecto.Migration

  def change do
    create table(:spotify_playlists) do
      add :playlist_id, :string
      add :spotify_id, :string

      timestamps()
    end

  end
end
