defmodule PR.SonosHouseholds.GroupManager do
  require Logger

  alias PR.SonosHouseholds
  alias PR.SonosHouseholds.Group
  alias PR.SonosAPI

  def check_groups do
    # TODO maybe if this doesn't work, refetch groups, look for one with the same name
    # maybe player ids and then set that as the current group here
    Logger.info("Checking active group")

    with {:ok, groups} <- get_sonos_groups(),
         {:ok, active_group_id, active_group_name, player_ids} <- get_active_group(),
         {:ok, matching_group_id} = group_name_present?(groups, active_group_name) do
      # This gets all the groups and looks in there for the active group_id
      # maybe it should look up the active group BY id, if that gives the GONE response,
      # then perhaps it should be recreated. 

      # OR, look for one with the same name and update the id on the active group
      Logger.info("Group named #{active_group_name} still exists on Sonos")
      :ok
    else
      {:error, :group_name_is_gone} ->
        Logger.warn("Check groups: Group #{active_group_name} isn't present on Sonos. Recreating with player ids")
        recreate_group(player_ids)
      {:error, :cant_get_groups} ->
        Logger.error("Check groups: Can't get groups")
        {:error, "Can't get Sonos groups"}

      {:error, :no_active_group} ->
        Logger.error("Check groups: No active group")
        {:error, "Group not set"}

      {:error, :no_household_activated} ->
        Logger.error("Check groups: No household activated")
        {:error, "Household not activated"}

      _ ->
        Logger.error("Check groups: Error")
        {:error, "Something didn't work"}
    end
  end

  @spec recreate_group(List.t()) :: :ok | {:error, String.t()}
  defp recreate_group(player_ids) do
    # Do this before making the new group
    Logger.info("Unsubscribing")
    SonosAPI.unsubscribe_webhooks()
    Logger.info("Trying to create group with player_ids", player_ids: player_ids)

    # Make a new group with the player ids from the last saved group
    case SonosAPI.create_group(player_ids) do
      {:ok, %Group{group_id: id}} ->
        SonosAPI.subscribe_webhooks()
        Logger.info("New group created #{id}")
        {:ok, "Re-created group"}

      {:error, :no_household_activated} ->
        Logger.error("Couldn't re-create group, no household activated")
        {:error, "Couldn't re-create group"}

      _ ->
        Logger.error("Couldn't re-create group")
        {:error, "Couldn't re-create group"}
    end
  end

  defp group_name_present?(groups, active_group_name) do
    case Enum.find(groups, & &1.name == active_group_name) do
      %{name: name, id: matching_group_id} ->
      {:ok, matching_group_id}
      _ ->
      {:error, :group_name_is_gone}
    end
  end

  @spec get_sonos_groups() :: {:ok, [map()]} | {:error, atom()}
  defp get_sonos_groups do
    case SonosAPI.get_groups() do
      {:ok, %{groups: groups}, _} ->
        {:ok, groups}

      {:error, msg} ->
        Logger.error("Can't get groups from Sonos API: #{msg}")
        {:error, msg}

      _ ->
        {:error, :cant_get_groups}
    end
  end

  @spec get_active_group() :: {:ok, String.t(), List.t()} | {:error, atom()}
  def get_active_group do
    # Get Group ID and expected player_ids from the database
    case SonosHouseholds.get_active_group() do
      %Group{id: active_group_id, name: name, player_ids: player_ids} ->
        {:ok, active_group_id, name, player_ids}

      _ ->
        {:error, :no_active_group}
    end
  end
end
