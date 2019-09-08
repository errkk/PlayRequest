defmodule PR.Repo.Migrations.CreateGroups do
  use Ecto.Migration

  def change do
    create table(:groups) do
      add :group_id, :string
      add :name, :string
      add :player_ids, {:array, :string}
      add :is_active, :boolean, default: false, null: false
      add :subscribed_at, :utc_datetime

      add :household_id, references(:households, on_delete: :nothing)

      timestamps()
    end

    create index(:groups, [:household_id])
    create unique_index(:groups, [:group_id])
  end
end
