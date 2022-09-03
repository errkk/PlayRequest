defmodule PR.SonosHouseholds.GroupManager do
  require Logger

  alias PR.SonosHouseholds
  alias PR.SonosHouseholds.Group
  alias PR.SonosAPI

  def check_groups do
    with {:ok, groups} <- get_groups(),
         {:ok, expected_group_id, player_ids} <- get_active_group_id() do
      if groups
         |> Enum.map(& &1.id)
         |> Enum.member?(expected_group_id) do
        Logger.info("Group ok #{expected_group_id}")
        :ok
      else
        Logger.error("Active group #{expected_group_id} not found. Trying to recreate.")
        handle_mismatch(player_ids)
        {:error, :mismatch}
      end
    else
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

  @spec handle_mismatch(List.t()) :: :ok | {:error, String.t()}
  defp handle_mismatch(player_ids) do
    SonosAPI.unsubscribe_webhooks()

    case SonosAPI.create_group(player_ids) do
      {:ok, %Group{id: id}} ->
        SonosAPI.subscribe_webhooks()
        Logger.info("New group created")
        {:ok, "Recreated group"}

      _ ->
        Logger.error("Couldn't recreate group")
        {:error, "Couldn't recreate group"}
    end
  end

  @spec get_groups() :: {:ok, [map()]} | {:error, atom()}
  defp get_groups do
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

  @spec get_active_group_id() :: {:ok, String.t(), List.t()} | {:error, atom()}
  def get_active_group_id do
    # Get Group ID and expected player_ids from the database
    case SonosHouseholds.get_active_group() do
      %Group{group_id: group_id, player_ids: player_ids} ->
        {:ok, group_id, player_ids}

      _ ->
        {:error, :no_active_group}
    end
  end
end
