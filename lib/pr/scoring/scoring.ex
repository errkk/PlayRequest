defmodule PR.Scoring do
  @moduledoc """
  The Scoring context.
  """

  import Ecto.Query, warn: false
  alias PR.Repo

  alias PR.Scoring.Point
  alias PR.Queue.Track
  alias PR.Auth.User
  alias PR.Music

  def list_points do
    Repo.all(Point)
  end

  def list_top_scorers do
    User
    |> join(:right, [u], t in assoc(u, :tracks),
      on: fragment("?::date", t.inserted_at) == ^Date.utc_today(),
      as: :tracks
    )
    |> join(:right, [u, tracks: t], p in assoc(t, :points),
      on: fragment("?::date", p.inserted_at) == ^Date.utc_today(),
      as: :points
    )
    |> where([u, points: p], p.reason == :like)
    |> group_by([u], u.id)
    |> having([u], not is_nil(u.id))
    |> select([u], %{u | points_received: count(1)})
    |> order_by([u], desc: fragment("count(1)"))
    |> Repo.all()
  end

  @doc """
  Counts likes and super likes that a user has received
  returns: %{likes: 0, super_likes: 0}
  """
  def count_likes_received(%User{} = user) do
    Point
    |> query_for_recipient(user)
    |> query_for_today()
    |> aggregate_points()
    |> Repo.all()
    |> remap_aggregates()
  end

  @doc """
  Counts likes and super likes that a user has given
  returns: %{likes: 0, super_likes: 0}
  """
  def count_likes_sent(%User{} = user) do
    Point
    |> query_for_sender(user)
    |> query_for_today()
    |> aggregate_points()
    |> Repo.all()
    |> remap_aggregates()
  end

  def create_point(attrs \\ %{}) do
    %Point{}
    |> Point.changeset(attrs)
    |> Repo.insert()
    |> case do
      {:ok, point} = res ->
        point
        |> Repo.preload([:track, :user])
        |> Music.broadcast(:point)

        res

      res ->
        res
    end
  end

  defp remap_aggregates(results) do
    results
    |> Enum.reduce(
      %{likes: 0, super_likes: 0, burns: 0},
      fn
        [:like, likes], acc -> Map.put(acc, :likes, likes)
        [:super_like, super_likes], acc -> Map.put(acc, :super_likes, super_likes)
        [:burn, burns], acc -> Map.put(acc, :burns, burns)
      end
    )
  end

  defp query_for_recipient(query, %User{id: user_id}) do
    query
    |> join(
      :right,
      [p],
      t in Track,
      on: t.id == p.track_id and t.user_id == ^user_id,
      as: :points
    )
  end

  defp query_for_sender(query, %User{id: user_id}) do
    query
    |> where([p], p.user_id == ^user_id)
  end

  @spec query_for_today(Ecto.Queryable.t()) :: Ecto.Queryable.t()
  defp query_for_today(query) do
    query
    |> where([p], fragment("?::date", p.inserted_at) == ^Date.utc_today())
  end

  defp aggregate_points(query) do
    query
    |> group_by(:reason)
    |> select([p], [p.reason, count(p.reason)])
  end
end
