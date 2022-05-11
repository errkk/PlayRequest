defmodule PR.Repo.Migrations.RemovePlayers do
  use Ecto.Migration

  def change do
    drop table(:players)
  end
end
