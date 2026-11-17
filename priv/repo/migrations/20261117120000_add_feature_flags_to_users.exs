defmodule PR.Repo.Migrations.AddFeatureFlagsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :feature_flags, {:array, :string}, default: [], null: false
    end
  end
end
