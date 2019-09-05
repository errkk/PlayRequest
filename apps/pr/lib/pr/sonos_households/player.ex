defmodule PR.SonosHouseholds.Player do
  use Ecto.Schema
  import Ecto.Changeset

  alias PR.SonosHouseholds.Household

  schema "players" do
    field :label, :string
    field :player_id, :string
    field :is_active, :boolean, default: false

    belongs_to :household, Household

    timestamps()
  end

  @doc false
  def changeset(players, attrs) do
    players
    |> cast(attrs, [:player_id, :label, :is_active, :household_id])
    |> validate_required([:player_id, :label, :household_id])
    |> unique_constraint(:player_id)
  end
end
