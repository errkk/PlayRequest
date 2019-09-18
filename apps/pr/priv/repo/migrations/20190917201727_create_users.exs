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
      add :is_trusted, :boolean

      timestamps()
    end

    create unique_index(:users, [:email])

    alter table(:tracks) do
      add :user_id, references(:users)
    end
  end
end
