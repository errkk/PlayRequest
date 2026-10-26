defmodule PR.Repo.Migrations.AddMergedIntoToUsers do
  use Ecto.Migration

  # Some people have more than one account (personal email, name change).
  # merged_into_id points a duplicate at the account it belongs to, so stats
  # can count them as one person.

  # {duplicate, canonical} user ids in production
  @merges [{1, 22}, {76, 65}, {64, 41}, {116, 91}, {106, 98}, {118, 73}, {115, 37}, {35, 95}]

  def up do
    alter table(:users) do
      add :merged_into_id, references(:users, on_delete: :nilify_all)
    end

    flush()

    # Only applies where both rows exist, so other environments are untouched
    # unless their ids happen to line up
    for {dup, canonical} <- @merges do
      execute """
        UPDATE users SET merged_into_id = #{canonical}
        WHERE id = #{dup} AND EXISTS (SELECT 1 FROM users WHERE id = #{canonical})
      """
    end
  end

  def down do
    alter table(:users) do
      remove :merged_into_id
    end
  end
end
