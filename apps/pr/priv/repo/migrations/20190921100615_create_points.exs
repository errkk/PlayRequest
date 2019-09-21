defmodule PR.Repo.Migrations.CreatePoints do
  use Ecto.Migration

  def change do
    create table(:points) do
      add :user_id, references(:users, on_delete: :nothing)
      add :track_id, references(:tracks, on_delete: :nothing)

      timestamps()
    end

    create index(:points, [:user_id])
    create index(:points, [:track_id])

    create unique_index(:points, [:user_id, :track_id], name: :user_track)
  end
end
