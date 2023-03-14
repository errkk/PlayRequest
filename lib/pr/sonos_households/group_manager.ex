defmodule PR.SonosHouseholds.GroupManager do
  require Logger

  alias PR.SonosHouseholds
  alias PR.SonosHouseholds.Group
  alias PR.SonosAPI

  @retries 5

  def check_groups do
    # Fetch groups from SonosAPI look for one that has the same name as the one that's stored
    # If not, the players may have become un-grouped, so create and save a new group with the
    # player ids that we had before.
    Logger.info("Checking active group")

    SonosHouseholds.get_active_group()
    |> check_or_recrate_active_group(@retries)
  end

  defp check_or_recrate_active_group(
         %Group{group_id: active_group_id, player_ids: player_ids},
         retries
       ) do
    with {:ok, groups} <- get_sonos_groups(),
         {:ok, active_group_id} <-
           group_id_present?(groups, active_group_id) do
      Logger.info("Group #{active_group_id} still exists on Sonos")

      # Resubscribes after groupstatus gone, which i thin unsubscribes
      # TODO it only matches on group name, so might need to update the group id
      # saved here, in case that has changed
      Logger.info("Resubscribing webhooks for group #{active_group_id}")
      SonosAPI.subscribe_webhooks()

      :ok
    else
      {:error, :no_household_activated} ->
        :ok

      {:error, :group_id_is_gone} ->
        Logger.warn(
          "Check groups: Group #{active_group_id} isn't present on Sonos. Recreating with player ids",
          player_ids: player_ids
        )

        recreate_group(player_ids)

      {:error, :cant_get_groups} ->
        # This has happened when this is run from the group_status_change webhook
        # The household/groups endpoint returns GONE, so might be to do with the network going down
        # Maybe this could trigger a delay before re accessing the group (or poll it?)
        # When the GONE case happens, i think it kills the webhook subscription.
        # So if the group can found after getting here, probs needs a resubscription
        Logger.warn(
          "Couldn't retrieve Sonos groups when trying to check_groups. Retry in 10sec",
          player_ids: player_ids,
          active_group_id: active_group_id,
          retries: retries
        )

        # TODO maybe this should be a GenServer if we don't wanna leave the 
        # webhook connection open doing it synchronously
        Application.get_env(:pr, :sleep)
        |> Process.sleep()

        Logger.warn("Retrying #{retries}")
        # Flag to say its a retry from here, in which case the ok state needs to resubscribe?
        check_or_recrate_active_group(
          %Group{id: active_group_id, player_ids: player_ids},
          retries - 1
        )

      {:error, reason} ->
        Logger.error("Check groups: #{Atom.to_string(reason)}")
        {:error, "Group not set"}

      _ ->
        Logger.error("Check groups: Error")
        {:error, "Something didn't work"}
    end
  end

  defp check_or_recrate_active_group(_, _) do
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

  defp group_id_present?(groups, active_group_id) do
    if Enum.any?(groups, &match?(%{id: ^active_group_id}, &1)) do
      {:ok, active_group_id}
    else
      {:error, :group_id_is_gone}
    end
  end

  @spec get_sonos_groups() :: {:ok, [map()]} | {:error, atom()}
  defp get_sonos_groups do
    case SonosAPI.get_groups() do
      {:ok, %{groups: groups}, _} ->
        {:ok, groups}

      {:error, :no_household_activated} ->
        {:error, :no_household_activated}

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
