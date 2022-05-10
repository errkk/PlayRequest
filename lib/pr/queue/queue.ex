defmodule PR.Queue do
  @moduledoc """
  The Queue context.
  """

  require Logger
  import Ecto.Query, warn: false
  alias PR.Repo

  alias PR.Queue
  alias PR.Queue.{Track, TrackScore}
  alias PR.Music.SonosItem
  alias PR.Auth.User
  alias PR.Scoring.Point

  def list_tracks do
    Repo.all(Track)
  end

  @spec list_todays_tracks(User.t()) :: [Track.t()]
  def list_todays_tracks(%User{id: user_id}) do
    Track
    |> query_for_today()
    |> query_given_points(user_id)
    |> query_received_points()
    |> query_played()
    |> query_track_score()
    |> select_user_facing_fields()
    |> order()
    |> preload(:user)
    |> Repo.all()
  end

  @spec list_unplayed(User.t()) :: [Track.t()]
  def list_unplayed(%User{id: user_id}) do
    Track
    |> query_unplayed()
    |> query_given_points(user_id)
    |> query_received_points()
    |> query_track_score()
    |> select_user_facing_fields()
    |> order()
    |> limit(100)
    |> preload(:user)
    |> Repo.all()
  end

  @spec get_playing() :: Track.t()
  def get_playing do
    Track
    |> query_is_playing()
    |> limit(1)
    |> Repo.one()
  end

  @spec has_unplayed() :: integer()
  def has_unplayed do
    Track
    |> query_unplayed()
    |> query_unplaying()
    |> Repo.aggregate(:count, :id)
  end

  @spec num_unplayed() :: integer()
  def num_unplayed do
    Track
    |> query_unplayed()
    |> Repo.aggregate(:count, :id)
  end

  @spec list_track_uris() :: [String.t()]
  def list_track_uris do
    Track
    |> query_unplayed()
    |> order()
    |> limit(100)
    |> select([t], {t.spotify_id})
    |> Repo.all()
  end

  @spec has_participated?(User.t()) :: boolean()
  def has_participated?(%User{id: user_id} = user) do
    case Track
    |> query_for_user(user)
    |> Repo.aggregate(:count, :id) do
      0 -> false
      _ -> true
    end
  end

  @spec get_track!(integer()) :: Track.t()
  def get_track!(id), do: Repo.get!(Track, id)

  @spec get_track(integer()) :: Track.t() | nil
  def get_track(id), do: Repo.get(Track, id)

  @spec create_track(map()) :: {:ok, Track.t()} | {:error, Ecto.Changeset.t()}
  def create_track(attrs \\ %{}) do
    %Track{}
    |> Track.changeset(attrs)
    |> Repo.insert()
  end

  @spec update_track(Track.t(), map()) :: {:ok, Track.t()} | {:error, Ecto.Changeset.t()}
  def update_track(%Track{} = track, attrs) do
    track
    |> Track.changeset(attrs)
    |> Repo.update()
  end

  @spec mark_played(Track.t()) :: {:ok, Track.t()} | {:error, Ecto.Changeset.t()}
  def mark_played(%Track{} = track) do
    update_track(track, %{played_at: DateTime.utc_now()})
  end

  @spec mark_unplayed(Track.t()) :: {:ok, Track.t()} | {:error, Ecto.Changeset.t()}
  def mark_unplayed(%Track{} = track) do
    update_track(track, %{played_at: nil})
  end

  @spec delete_track(Track.t()) :: {:ok, Track.t()} | {:error, Ecto.Changeset.t()}
  def delete_track(%Track{} = track) do
    Repo.delete(track)
  end

  @spec change_track(Track.t()) :: Ecto.Changeset.t()
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

  def set_current(_) do
    Logger.info("Nothing playing, clearing playing_since")

    case Track
      |> query_is_playing()
      |> query_has_been_playing()
      |> Repo.update_all(set: [
        playing_since: nil,
        played_at: dynamic([i], datetime_add(i.playing_since, i.duration, "millisecond"))
      ]) do
      {0, nil} ->
        Logger.info("Set current, nothing updated")
        {:ok}
      {_, nil} ->
        Logger.info("Set current, something updated")
        {:ok}
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

  @spec get_playing_since() :: {:already_started, DateTime.t()} | {:ok}
  defp get_playing_since do
    case get_playing() do
      %Track{playing_since: playing_since} -> {:already_started, playing_since}
      _ -> {:ok}
    end
  end

  @spec bump() :: {:ok}
  def bump do
    set_current(%{})
  end

  @spec query_is_playing(Ecto.Queryable.t()) :: Ecto.Queryable.t()
  defp query_is_playing(query) do
    query
    |> where([t], not is_nil(t.playing_since))
  end

  @spec query_has_been_playing(Ecto.Queryable.t()) :: Ecto.Queryable.t()
  defp query_has_been_playing(query) do
    query
    |> where([t], t.playing_since < ago(10, "second"))
  end

  @spec query_unplayed(Ecto.Queryable.t()) :: Ecto.Queryable.t()
  defp query_unplayed(query) do
    query
    |> where([t], is_nil(t.played_at))
  end

  @spec query_unplaying(Ecto.Queryable.t()) :: Ecto.Queryable.t()
  defp query_unplaying(query) do
    query
    |> where([t], is_nil(t.playing_since))
  end

  @spec query_played(Ecto.Queryable.t()) :: Ecto.Queryable.t()
  defp query_played(query) do
    query
    |> where([t], not is_nil(t.played_at))
  end

  @spec query_given_points(Ecto.Queryable.t(), integer()) :: Ecto.Queryable.t()
  defp query_given_points(query, user_id) do
    query
    |> join(
      :left, [t],
      p in Point,
      on: t.id == p.track_id and p.user_id == ^user_id,
      as: :given_point
    )
  end

  @spec query_received_points(Ecto.Queryable.t()) :: Ecto.Queryable.t()
  defp query_received_points(query) do
    query
    |> join(
      :left, [t],
      p in subquery(points_for()),
      on: t.id == p.track_id,
      as: :received_points
    )
  end

  @spec query_track_score(Ecto.Queryable.t()) :: Ecto.Queryable.t()
  defp query_track_score(query) do
    query
    |> join(
      :left, [t],
      s in TrackScore,
      on: t.spotify_id == s.spotify_id,
      as: :track_score
    )
  end

  @spec points_for() :: Ecto.Queryable.t()
  defp points_for() do
    Point
    |> group_by([p], p.track_id)
    |> select([p], %{track_id: p.track_id, points_received: count(p.id)})
  end

  @spec query_for_user(Ecto.Queryable.t(), User.t()) :: Ecto.Queryable.t()
  defp query_for_user(query, %User{id: user_id}) do
    query
    |> where([t], t.user_id == ^user_id)
  end

  @spec query_for_today(Ecto.Queryable.t()) :: Ecto.Queryable.t()
  defp query_for_today(query) do
    query
    |> where([t], fragment("?::date", t.inserted_at) == ^Date.utc_today())
  end

  @spec order(Ecto.Queryable.t()) :: Ecto.Queryable.t()
  defp order(query) do
    query
    |> order_by([t], asc: t.inserted_at)
  end

  @spec select_user_facing_fields(Ecto.Queryable.t()) :: Ecto.Queryable.t()
  defp select_user_facing_fields(query) do
    query
    |> select([t, given_point: gp, received_points: rp, track_score: ts], %{
      t |
      has_pointed: not is_nil(gp.id),
      points_received: rp.points_received,
      score: ts.score,
      artist_score: ts.artist_score
    })

  end
end
