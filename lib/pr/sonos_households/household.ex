defmodule PR.SonosHouseholds.Household do
  use Ecto.Schema
  import Ecto.Changeset

  schema "households" do
    field(:household_id, :string)
    field(:is_active, :boolean, default: false)
    field(:label, :string)

    timestamps()
  end

  @doc false
  def changeset(households, attrs) do
    households
    |> cast(attrs, [:household_id, :label, :is_active])
    |> validate_required([:household_id])
    |> unique_constraint(:household_id)
  end
end
