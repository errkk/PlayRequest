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
    |> group_by([u], u.id)
    |> having([u], not is_nil(u.id))
    |> select([u], %{u | points_received: count(1)})
    |> order_by([u], desc: fragment("count(1)"))
    |> Repo.all()
  end

  # deprecate
  def count_points(%User{} = user) do
    Point
    |> query_for_user(user)
    |> query_for_today()
    |> Repo.aggregate(:count, :id)
  end

  def count_likes(%User{} = user) do
    Point
    |> query_for_user(user)
    |> query_for_today()
    |> group_by(:is_super)
    |> select([p], [p.is_super, count(p.is_super)])
    |> Repo.all()
    |> Enum.reduce(
      %{likes: 0, super_likes: 0},
      fn
        [false, likes], acc -> Map.put(acc, :likes, likes)
        [true, super_likes], acc -> Map.put(acc, :super_likes, super_likes)
      end
    )
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

  defp query_for_user(query, %User{id: user_id}) do
    query
    |> join(
      :right,
      [p],
      t in Track,
      on: t.id == p.track_id and t.user_id == ^user_id,
      as: :points
    )
  end

  @spec query_for_today(Ecto.Queryable.t()) :: Ecto.Queryable.t()
  defp query_for_today(query) do
    query
    |> where([p], fragment("?::date", p.inserted_at) == ^Date.utc_today())
  end
end
