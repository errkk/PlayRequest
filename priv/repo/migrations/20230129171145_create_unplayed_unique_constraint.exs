defmodule PR.Repo.Migrations.CreateUnplayedUniqueConstraint do
  use Ecto.Migration

  def change do
    create unique_index(:tracks, [:spotify_id], where: "played_at is null", name: :already_queued)
  end
end
