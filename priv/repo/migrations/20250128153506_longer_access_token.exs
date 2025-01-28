defmodule PR.Repo.Migrations.LongerAccessToken do
  use Ecto.Migration

  def up do
    alter table(:tokens) do
      modify :access_token, :text
      modify :refresh_token, :text
    end
  end

  def down do
    alter table(:tokens) do
      modify :access_token, :string, size: 255
      modify :refresh_token, :string, size: 255
    end
  end
end
