defmodule PR.Queue do
  @moduledoc """
  The Queue context.
  """

  import Ecto.Query, warn: false
  alias PR.Repo

  alias PR.Queue.Track

  def list_tracks do
    Repo.all(Track)
  end

  def list_unplayed do
    Track
    |> query_unplayed()
    |> limit(100)
    |> Repo.all()
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

  defp query_unplayed(query) do
    query
    |> where([t], is_nil(t.played_at))
    |> order_by([t], asc: t.inserted_at)
  end
end
