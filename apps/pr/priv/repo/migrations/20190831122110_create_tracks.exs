defmodule PR.Repo.Migrations.CreateTracks do
  use Ecto.Migration

  def change do
    create table(:tracks) do
      add :name, :string
      add :artist, :string
      add :img, :string
      add :spotify_id, :string
      add :duration, :integer
      add :played_at, :utc_datetime

      timestamps()
    end

  end
end
