defmodule PR.Queue do
  @moduledoc """
  The Queue context.
  """

  require Logger
  import Ecto.Query, warn: false
  alias PR.Repo

  alias PR.Queue
  alias PR.Queue.Track
  alias PR.Music.SonosItem
  alias PR.Auth.User
  alias PR.Scoring.Point

  def list_tracks do
    Repo.all(Track)
  end

  def list_todays_tracks(%User{id: user_id}) do
    Track
    |> query_today()
    |> query_given_points(user_id)
    |> query_received_points()
    |> query_played()
    |> select_user_facing_fields()
    |> order()
    |> preload(:user)
    |> Repo.all()
  end

  def list_unplayed(%User{id: user_id}) do
    Track
    |> query_unplayed()
    |> query_given_points(user_id)
    |> query_received_points()
    |> select_user_facing_fields()
    |> order()
    |> limit(100)
    |> preload(:user)
    |> Repo.all()
  end

  def get_playing do
    Track
    |> query_is_playing()
    |> limit(1)
    |> Repo.one()
  end

  def has_unplayed do
    Track
    |> query_unplayed()
    |> query_unplaying()
    |> Repo.aggregate(:count, :id)
  end

  def num_unplayed do
    Track
    |> query_unplayed()
    |> Repo.aggregate(:count, :id)
  end

  def list_track_uris do
    Track
    |> query_unplayed()
    |> order()
    |> limit(100)
    |> select([t], {t.spotify_id})
    |> Repo.all()
  end

  def has_participated?(%User{id: user_id} = user) do
    case Track
    |> query_for_user(user)
    |> Repo.aggregate(:count, :id) do
      0 -> false
      _ -> true
    end
  end

  def get_track!(id), do: Repo.get!(Track, id)
  def get_track(id), do: Repo.get(Track, id)

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

  @spec set_current(SonosItem.t()) :: {:started | :already_started, DateTime.t()} | {:ok}
  def set_current(%SonosItem{spotify_id: spotify_id}) do
    Logger.info("Updating current track")
    now = DateTime.utc_now()

    case set_current_transaction(spotify_id, now) do
      {:ok, {0, nil}} ->
        get_playing_since()
      {:ok, {_, nil}} ->
        {:started, now}
    end
  end

  @spec set_current_transaction(String.t(), DateTime.t()) :: {:ok, {integer(), any()}}
  defp set_current_transaction(spotify_id, now) do
    Repo.transaction(fn ->
      # Anything else that was playing now isn't, cos this new track is
      Track
      |> query_is_playing()
      |> where([t], t.spotify_id != ^spotify_id)
      |> Repo.update_all(set: [playing_since: nil, played_at: now])

      # Update the track that's playing by spotify id
      # If its not already played or already marked as playing
      Track
      |> where([t], t.spotify_id == ^spotify_id)
      |> where([t], is_nil(t.played_at))
      |> where([t], is_nil(t.playing_since))
      |> Repo.update_all(set: [playing_since: now])
    end)
  end

  defp get_playing_since do
    case get_playing() do
      %Track{playing_since: playing_since} -> {:already_started, playing_since}
      _ -> {:ok}
    end
  end

  def set_current(_) do
    Logger.info("Nothing playing, clearing playing_since")

    Track
    |> query_is_playing()
    |> Repo.update_all(set: [
      playing_since: nil,
      played_at: dynamic([i], date_add(i.playing_since, i.duration, "millisecond"))
    ])
    {:ok}
  end

  def bump do
    set_current(%{})
  end

  defp query_is_playing(query) do
    query
    |> where([t], not is_nil(t.playing_since))
  end

  defp query_unplayed(query) do
    query
    |> where([t], is_nil(t.played_at))
  end

  defp query_unplaying(query) do
    query
    |> where([t], is_nil(t.playing_since))
  end

  defp query_played(query) do
    query
    |> where([t], not is_nil(t.played_at))
  end

  defp query_given_points(query, user_id) do
    query
    |> join(
      :left, [t],
      p in Point,
      on: t.id == p.track_id and p.user_id == ^user_id,
      as: :given_point
    )
  end

  defp query_received_points(query) do
    query
    |> join(
      :left, [t],
      p in subquery(points_for()),
      on: t.id == p.track_id,
      as: :received_points
    )
  end

  defp query_for_user(query, %User{id: user_id}) do
    query
    |> where([t], t.user_id == ^user_id)
  end

  defp query_today(query) do
    query
    |> where([t], fragment("?::date", t.inserted_at) == ^Date.utc_today())
  end

  defp order(query) do
    query
    |> order_by([t], asc: t.inserted_at)
  end

  defp points_for() do
    Point
    |> group_by([p], p.track_id)
    |> select([p], %{track_id: p.track_id, points: count(p.id)})
  end

  defp select_user_facing_fields(query) do
    query
    |> select([t, given_point: gp, received_points: rp], %{
      t |
      has_pointed: not is_nil(gp.id),
      points: rp.points
    })

  end
end
