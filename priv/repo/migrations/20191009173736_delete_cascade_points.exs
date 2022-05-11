defmodule PR.Repo.Migrations.DeleteCascadePoints do
  use Ecto.Migration

  def up do
    execute "ALTER TABLE points DROP CONSTRAINT points_user_id_fkey"
    execute "ALTER TABLE points DROP CONSTRAINT points_track_id_fkey"

    alter table(:points) do
      modify :user_id, references(:users, on_delete: :delete_all)
      modify :track_id, references(:tracks, on_delete: :delete_all)
    end
  end

  def down do
    execute "ALTER TABLE points DROP CONSTRAINT points_user_id_fkey"
    execute "ALTER TABLE points DROP CONSTRAINT points_track_id_fkey"

    alter table(:points) do
      modify :user_id, references(:users, on_delete: :nothing)
      modify :track_id, references(:tracks, on_delete: :nothing)
    end
  end
end
