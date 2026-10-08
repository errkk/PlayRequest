defmodule PR.Repo.Migrations.AddErrorCountToTracks do
  use Ecto.Migration

  def change do
    alter table(:tracks) do
      add :error_count, :integer, null: false, default: 0
    end
  end
end
