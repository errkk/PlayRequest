defmodule PR.Repo.Migrations.AddReasonToLike do
  use Ecto.Migration

  def up do
    execute ~s"""
      CREATE TYPE point_reason AS ENUM ('like', 'super_like', 'burn');
    """

    execute ~s"""
      DELETE FROM points where is_super;
    """

    alter table(:points) do
      remove :is_super
      add :reason, :point_reason, default: "like"
    end
  end

  def down do
    alter table(:points) do
      remove :reason
      add :is_super, :boolean, default: false
    end

    execute ~s"""
      DROP TYPE point_reason;
    """
  end
end
