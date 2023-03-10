defmodule PR.SonosHouseholds.GroupManager do
  require Logger

  alias PR.SonosHouseholds
  alias PR.SonosHouseholds.Group
  alias PR.SonosAPI

  def check_groups do
    # Fetch groups from SonosAPI look for one that has the same name as the one that's stored
    # If not, the players may have become un-grouped, so create and save a new group with the
    # player ids that we had before.
    Logger.info("Checking active group")

    SonosHouseholds.get_active_group()
    |> check_or_recrate_active_group()
  end

  defp check_or_recrate_active_group(%Group{name: active_group_name, player_ids: player_ids}) do
    with {:ok, groups} <- get_sonos_groups(),
         {:ok, active_group_name} <- group_name_present?(groups, active_group_name) do
      Logger.info("Group named #{active_group_name} still exists on Sonos")
      # TODO maybe resubscribe to webhooks here?
      :ok
    else
      {:error, :group_name_is_gone} ->
        Logger.warn(
          "Check groups: Group #{active_group_name} isn't present on Sonos. Recreating with player ids",
          player_ids: player_ids
        )

        recreate_group(player_ids)

      {:error, :cant_get_groups} ->
        # This has happened when this is run from the group_status_change webhook
        # The household/groups endpoint returns GONE, so might be to do with the network going down
        # Maybe this could trigger a delay before re accessing the group (or poll it?)
        # When the GONE case happens, i think it kills the webhook subscription.
        # So once the group is found after getting here, probs needs a resubscription
        Logger.warn(
          "Couldn't retrieve Sonos groups when trying to check_groups. Retry in 10sec",
          player_ids: player_ids,
          active_group_name: active_group_name
        )

        Process.sleep(10_000)
        Logger.info("Retrying")
        check_groups()

      {:error, reason} ->
        Logger.error("Check groups: #{Atom.to_string(reason)}")
        {:error, "Group not set"}

      _ ->
        Logger.error("Check groups: Error")
        {:error, "Something didn't work"}
    end
  end

  defp check_or_recrate_active_group(_) do
    Logger.error("No active group selected")
    :ok
  end

  @spec recreate_group(List.t()) :: {:ok, String.t()} | {:error, String.t()}
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
        {:ok, id}

      {:error, :no_household_activated} ->
        Logger.error("Couldn't re-create group, no household activated")
        {:error, :no_household_activated}

      _ ->
        Logger.error("Couldn't re-create group")
        {:error, :couldnt_recreate_group}
    end
  end

  defp group_name_present?(groups, active_group_name) do
    if Enum.any?(groups, &match?(%{name: ^active_group_name}, &1)) do
      {:ok, active_group_name}
    else
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
        {:error, :cant_get_groups}

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
