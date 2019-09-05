defmodule PR.SonosHouseholds do
  @moduledoc """
  The SonosHouseholds context.
  """

  import Ecto.Query, warn: false
  alias PR.Repo

  alias PR.SonosHouseholds.Household
  alias PR.SonosHouseholds.Player

  def list_houeholds do
    Repo.all(Household)
  end

  def get_household!(id), do: Repo.get!(Household, id)

  def get_active_household!() do
    Household
    |> where([h], h.is_active)
    |> limit(1)
    |> Repo.one!()
  end

  def create_households(attrs \\ %{}) do
    %Household{}
    |> Household.changeset(attrs)
    |> Repo.insert()
  end

  def insert_or_update_household(%{household_id: household_id} = changes) do
    case Repo.get_by(Household, household_id: household_id) do
      nil  -> %Household{household_id: household_id}
      household -> household
    end
    |> Household.changeset(changes)
    |> Repo.insert_or_update()
  end

  def update_household(%Household{} = household, attrs) do
    household
    |> Household.changeset(attrs)
    |> Repo.update()
  end

  def delete_household(%Household{} = household) do
    Repo.delete(household)
  end

  def change_household(%Household{} = household) do
    Household.changeset(household, %{})
  end


  #
  # Players
  #

  def list_players do
    Repo.all(Player)
  end

  def get_players!(id), do: Repo.get!(Player, id)

  def create_players(attrs \\ %{}) do
    %Player{}
    |> Player.changeset(attrs)
    |> Repo.insert()
  end

  def insert_or_update_player(%{player_id: player_id} = changes) do
    case Repo.get_by(Player, player_id: player_id) do
      nil  -> %Player{player_id: player_id}
      player -> player
    end
    |> Player.changeset(changes)
    |> Repo.insert_or_update()
  end

  def update_players(%Player{} = players, attrs) do
    players
    |> Player.changeset(attrs)
    |> Repo.update()
  end

  def delete_players(%Player{} = players) do
    Repo.delete(players)
  end

  def change_players(%Player{} = players) do
    Player.changeset(players, %{})
  end
end
