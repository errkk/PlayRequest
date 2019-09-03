defmodule PR.Music do
  alias PR.SpotifyAPI
  alias PR.Music.SearchTrack
  alias PR.Queue
  alias PR.Queue.Track

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
    with {:ok, search_track} <- get_track(id),
         {:ok, queued_track} <- create_track(search_track) do
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

  @spec get_playlist() :: [Track.t()]
  def get_playlist() do
    Queue.list_unplayed()
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
end
