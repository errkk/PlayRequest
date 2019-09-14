defmodule PR.Queue do
  @moduledoc """
  The Queue context.
  """

  require Logger
  import Ecto.Query, warn: false
  alias PR.Repo

  alias PR.Queue.Track
  alias PR.Music.SonosItem

  def list_tracks do
    Repo.all(Track)
  end

  def list_unplayed do
    Track
    |> query_unplayed()
    |> limit(100)
    |> Repo.all()
  end

  def has_unplayed do
    Track
    |> query_unplayed()
    |> query_unplaying()
    |> Repo.aggregate(:count, :id)
  end

  def list_track_uris do
    Track
    |> query_unplayed()
    |> limit(100)
    |> select([t], {t.spotify_id})
    |> Repo.all()
  end

  def get_track!(id), do: Repo.get!(Track, id)

  def create_track(attrs \\ %{}) do
    %Track{}
    |> Track.changeset(attrs)
    |> Repo.insert()
  end

  def update_track(%Track{} = track, attrs) do
    track
    |> Track.changeset(attrs)
    |> Repo.update()
  end

  def mark_played(%Track{} = track) do
    update_track(track, %{played_at: DateTime.utc_now()})
  end

  def delete_track(%Track{} = track) do
    Repo.delete(track)
  end

  def change_track(%Track{} = track) do
    Track.changeset(track, %{})
  end

  def set_current(%SonosItem{spotify_id: spotify_id}) do
    Logger.info("Updating current track")
    now = DateTime.utc_now()

    Repo.transaction(fn ->
      Track
      |> query_is_playing()
      |> where([t], t.spotify_id != ^spotify_id)
      |> Repo.update_all(set: [playing_since: nil, played_at: now])

      Track
      |> where([t], t.spotify_id == ^spotify_id)
      |> Repo.update_all(set: [playing_since: now])
    end)
  end

  def set_current(_) do
    Logger.info("Nothing playing, clearing playing_since")

    Track
    |> query_is_playing()
    |> Repo.update_all(set: [
      playing_since: nil,
      played_at: dynamic([i], date_add(i.playing_since, i.duration, "millisecond"))
    ])
  end

  defp query_is_playing(query) do
    query
    |> where([t], not is_nil(t.playing_since))
  end

  defp query_unplayed(query) do
    query
    |> where([t], is_nil(t.played_at))
    |> order_by([t], asc: t.inserted_at)
  end

  defp query_unplaying(query) do
    query
    |> where([t], is_nil(t.playing_since))
  end
end
