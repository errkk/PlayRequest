defmodule E.SonosHouseholds.Player do
  use Ecto.Schema
  import Ecto.Changeset

  alias E.SonosHouseholds.Household

  schema "players" do
    field :label, :string
    field :player_id, :string

    belongs_to :household, Household

    timestamps()
  end

  @doc false
  def changeset(players, attrs) do
    players
    |> cast(attrs, [:player_id, :label, :household_id])
    |> validate_required([:player_id, :label])
    |> unique_constraint(:player_id)
  end
end
