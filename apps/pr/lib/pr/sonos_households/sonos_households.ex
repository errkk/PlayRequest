defmodule PR.SonosHouseholds do
  @moduledoc """
  The SonosHouseholds context.
  """

  import Ecto.Query, warn: false
  alias PR.Repo

  alias PR.SonosHouseholds.{Household, Group}

  def list_houeholds do
    Repo.all(Household)
  end

  def get_household!(id), do: Repo.get!(Household, id)

  def get_active_household() do
    Household
    |> query_is_active()
    |> limit(1)
    |> Repo.one()
  end

  def get_active_household!() do
    Household
    |> query_is_active()
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
  # Groups
  #

  def list_groups do
    Repo.all(Group)
  end

  def get_group!(id), do: Repo.get!(Group, id)

  def get_active_group!() do
    Group
    |> query_is_active()
    |> limit(1)
    |> Repo.one!()
  end

  def get_active_group() do
    Group
    |> query_is_active()
    |> limit(1)
    |> Repo.one!()
  end


  def create_groups(attrs \\ %{}) do
    %Group{}
    |> Group.changeset(attrs)
    |> Repo.insert()
  end

  def insert_or_update_group(%{group_id: group_id} = changes) do
    case Repo.get_by(Group, group_id: group_id) do
      nil  -> %Group{group_id: group_id}
      group -> group
    end
    |> Group.changeset(changes)
    |> Repo.insert_or_update()
  end

  def update_group(%Group{} = group, attrs) do
    group
    |> Group.changeset(attrs)
    |> Repo.update()
  end

  def delete_group(%Group{} = group) do
    Repo.delete(group)
  end

  def change_group(%Group{} = group) do
    Group.changeset(group, %{})
  end

  defp query_is_active(query) do
    query
    |> where([h], h.is_active)
  end
end
