defmodule PR.Music do
  require Logger

  alias PR.SonosAPI
  alias PR.SpotifyAPI
  alias PR.Music.SearchTrack
  alias PR.Queue
  alias PR.Queue.Track
  alias PR.SonosHouseholds
  alias PR.SonosHouseholds.Group

  @topic inspect(__MODULE__)

  # API functions

  @doc "Use in the live view to receive updates"
  def subscribe do
    Phoenix.PubSub.subscribe(PRWeb.PubSub, @topic)
  end

  @spec search(String.t()) :: {:ok, [SearchTrack.t()]} | {:error}
  def search(q) do
    case SpotifyAPI.search(q) do
      {:ok, tracks} ->
        tracks =
          tracks
          |> Enum.map(&SearchTrack.new/1)
          {:ok, tracks}
      err -> err
    end
  end

  @spec queue(String.t()) :: {:ok, Track.t()}
  def queue(id) do
    Logger.info("Queuing #{id}")

    with {:ok, search_track} <- get_track(id),
         {:ok, queued_track} <- create_track(search_track) do
      broadcast(queued_track, :added)
      sync_playlist()
      {:ok, queued_track}
    else
      err -> err
    end
  end

  def sync_playlist do
    Queue.list_track_uris()
    |> Enum.map(fn {id} -> "spotify:track:" <> id end)
    |> SpotifyAPI.replace_playlist()
  end

  def load_playlist do
    sync_playlist()
    with %Group{group_id: group_id} <- SonosHouseholds.get_active_group!(),
         {:ok, %{items: sonos_favorites}, _} <- SonosAPI.get_favorites(),
         {:ok, fav_id} <- find_playlist(sonos_favorites),
         %{}  <- SonosAPI.set_favorite(fav_id, group_id) do
      {:ok}
    else
      {:error, :playlist_not_created} ->
        {:error, "Couldn't find #{get_playlist_name()} in Sonos favorites"}
      _ ->
        {:error, "Could not load playlist #{get_playlist_name()}"}
    end
  end

  @spec get_playlist() :: [Track.t()]
  def get_playlist() do
    Queue.list_unplayed()
  end

  def bump_and_reload do
    Queue.bump()
    load_playlist()
  end

  @spec find_playlist([map()]) :: {:ok, String.t()} | {:error, atom()}
  defp find_playlist(sonos_favorites) do
    case Enum.find(sonos_favorites, & &1.name == get_playlist_name()) do
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

  @spec broadcast(any(), :atom) :: no_return()
  defp broadcast(data, key) do
    Phoenix.PubSub.broadcast(PRWeb.PubSub, @topic, {__MODULE__, data, key})
  end

  defp get_playlist_name do
    Application.get_env(:pr, :playlist_name)
  end
end
