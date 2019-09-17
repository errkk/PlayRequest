defmodule PR.Repo.Migrations.CreateUsers do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :first_name, :string
      add :last_name, :string
      add :display_name, :string
      add :token, :string
      add :image, :string
      add :email, :string

      timestamps()
    end

    create unique_index(:users, [:email])
  end
end
