defmodule PR.Repo.Migrations.LongerUserToken do
  use Ecto.Migration

  def up do
    alter table(:users) do
      modify :token, :text
    end
  end

  def down do
    alter table(:users) do
      modify :token, :string, size: 255
    end
  end
end
