defmodule PR.Repo.Migrations.CreateTokens do
  use Ecto.Migration

  def change do
    create table(:tokens) do
      add :access_token, :string
      add :refresh_token, :string
      add :service, :string
      add :activated_at, :utc_datetime

      timestamps()
    end

  end
end
