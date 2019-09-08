defmodule PR.SonosHouseholds.Group do
  use Ecto.Schema
  import Ecto.Changeset

  alias PR.SonosHouseholds.Household

  schema "groups" do
    field :group_id, :string
    field :name, :string
    field :player_ids, {:array, :string}
    field :is_active, :boolean

    belongs_to :household, Household

    timestamps()
  end

  @doc false
  def changeset(group, attrs) do
    group
    |> cast(attrs, [:group_id, :name, :player_ids, :household_id, :is_active])
    |> validate_required([:group_id, :name, :player_ids, :household_id])
    |> unique_constraint(:group_id)
  end
end
