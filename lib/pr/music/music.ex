defmodule PR.Music do
  require Logger

  alias PR.SonosAPI
  alias PR.SpotifyAPI
  alias PR.PlayState
  alias PR.Music.{SearchTrack, PlaybackState}
  alias PR.Queue
  alias PR.Queue.Track
  alias PR.SonosHouseholds
  alias PR.SonosHouseholds.Group
  alias PR.Auth.User

  @topic inspect(__MODULE__)

  # API functions

  @doc "Use in the live view to receive updates"
  def subscribe do
    Phoenix.PubSub.subscribe(PR.PubSub, @topic)
  end

  @spec search(String.t()) :: {:ok, [SearchTrack.t()]} | {:error}
  def search(q) do
    case SpotifyAPI.search(q) do
      {:ok, tracks} ->
        tracks =
          tracks
          |> Enum.map(&SearchTrack.new/1)

        {:ok, tracks}

      err ->
        err
    end
  end

  @spec queue(User.t(), String.t()) :: {:ok, Track.t()}
  def queue(%User{id: user_id}, id) do
    Logger.info("Queuing: spotify:track:#{id}")

    with {:ok, search_track} <- get_track(id),
         search_track <- Map.put(search_track, :user_id, user_id),
         {:ok, queued_track} <- create_track(search_track) do
      queue_updated()

      if PlayState.is_idle?() do
        Logger.info("Track added while player is idle. Triggering playlist")
        trigger_playlist()
      else
        sync_playlist()
      end

      {:ok, queued_track}
    else
      err -> err
    end
  end

  def sync_playlist do
    Logger.info("Syncing tracks to Spotify playlist")

    Queue.list_track_uris()
    |> Enum.map(fn {id} -> "spotify:track:" <> id end)
    |> SpotifyAPI.replace_playlist()
    |> tap(fn _ -> Logger.debug("Spotify sync completed") end)

    {:ok}
  end

  # This take a little while to run, so there can be race conditions if it gets called
  # a few times, before it's had a chance to affect the play state
  def trigger_playlist(force \\ :dont_force) do
    with {:ok} <- sync_playlist(),
         {:ok} <- check_unplayed(),
         %Group{group_id: group_id} <- SonosHouseholds.get_active_group!(),
         {:ok, %{items: sonos_favorites}, _} <- SonosAPI.get_favorites(),
         {:ok, fav_id} <- find_playlist(sonos_favorites),
         {:ok} <- check_current_playstate(PlayState.get(:play_state), force),
         %{} <- SonosAPI.set_favorite(fav_id, group_id) do
      Logger.info("Trigger playlist: OK")
      {:ok}
    else
      {:error, :nothing_in_local_queue} ->
        Logger.warn("Trigger playlist: Nothing in local queue")
        {:error, "Nothing in local queue"}

      {:error, :playstate, state} ->
        Logger.warn("Trigger playlist: Canceling trigger_playlist, PlayState is now: #{state}")
        {:error, "Cancelled trigger, state is now #{state}"}

      {:error, :playlist_not_created} ->
        Logger.error("Trigger playlist: Playlist not created")
        {:error, "Couldn't find #{get_playlist_name()} in Sonos favorites"}

      {:error, :gone} ->
        Logger.error("Trigger playlist: Fav gone, try re-saving groups")
        {:error, "API Sez 'gone', try re-saving groups"}

      _ ->
        Logger.error("Trigger playlist: Unknown error")
        {:error, "Could not load playlist #{get_playlist_name()}"}
    end
  end

  def check_current_playstate(%PlaybackState{state: state}, :dont_force)
      when state in [:idle, :paused],
      do: {:ok}

  def check_current_playstate(%PlaybackState{state: state}, :force)
      when state in [:idle, :paused, :playing],
      do: {:ok}

  def check_current_playstate(%PlaybackState{state: state}, _mode),
    do: {:error, :playstate, state}

  def check_unplayed() do
    # Check if there's something in the queue
    # If might still be marked as playing if its a skip
    # but that's probably ok as this check is only really 
    # of interest for knowing what to do when skip is pressed
    cond do
      Queue.num_unplayed() == 0 ->
        {:error, :nothing_in_local_queue}

      true ->
        {:ok}
    end
  end

  def skip do
    # Tell sonos to skip to next track
    # If there is nothing else yet in the Sonos Queue then Sonos returns :no_content
    # There might be something in the  local queue, so we need to bump the current track out
    # and sync the revised playlist as the next update to sonos.
    # The trigger_playlist function returns an error tuple for any reason why that hasn't happened
    # Including if there are no more songs in the queue.
    # In this case, we need to rollback the bump that just happened.

    case SonosAPI.skip() do
      {:error, :no_content} ->
        Logger.notice("Skip – Nothing in Sonos queue, re-triggering")
        # Bump out current song from local playlist and re-trigger
        # Rollback the bump if trigger can't be performed
        PR.Repo.transaction(fn ->
          Queue.bump()

          case trigger_playlist(:force) do
            {:error, message} ->
              Logger.warn("Rolling back bump #{message}")
              # TODO this broadcasts to everyone, so might be better to route it
              # to a requester's id
              broadcast(:error, "Couldn't skip: #{message}")
              PR.Repo.rollback(:didnt_trigger_new_items)

            _ ->
              Logger.notice("Skip – Trigger succeeded")
          end
        end)

        {:ok, :bump_and_triggered}

      _ ->
        Logger.notice("Skip – Skipped")
        {:ok, :skipped}
    end
  end

  @spec get_playlist(User.t()) :: [Track.t()]
  def get_playlist(current_user) do
    Queue.list_unplayed(current_user)
  end

  def queue_updated do
    # Broadcase number of unplayed tracks
    Queue.num_unplayed()
    |> broadcast(:queue_updated)
  end

  def bump do
    Queue.bump()
    {:ok}
  end

  @spec broadcast(any(), :atom) :: no_return()
  def broadcast(data, key) do
    Phoenix.PubSub.broadcast(PR.PubSub, @topic, {__MODULE__, data, key})
  end

  @spec find_playlist([map()]) :: {:ok, String.t()} | {:error, atom()}
  defp find_playlist(sonos_favorites) do
    case Enum.find(sonos_favorites, &(&1.name == get_playlist_name())) do
      %{id: id} ->
        {:ok, id}

      _ ->
        {:error, :playlist_not_created}
    end
  end

  @spec create_track(SearchTrack.t()) :: {:ok, Track.t()}
  defp create_track(search_track) do
    search_track
    |> Map.delete(:__struct__)
    |> Queue.create_track()
  end

  @spec get_track(String.t()) :: {:ok, SearchTrack.t()} | {:error}
  defp get_track(id) do
    with track_data <- SpotifyAPI.get_track(id),
         %SearchTrack{} = track <- SearchTrack.new(track_data) do
      {:ok, track}
    else
      err -> err
    end
  end

  defp get_playlist_name do
    Application.get_env(:pr, :playlist_name)
  end
end
