defmodule PR.Repo.Migrations.AddSuperToLike do
  use Ecto.Migration

  def change do
    alter table(:points) do
      add :is_super, :boolean, default: false
    end
  end
end
