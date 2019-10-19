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

  @spec list_top_scorers() :: [User.t()]
  def list_top_scorers do
    User
    |> join(:right, [u], t in assoc(u, :tracks), as: :tracks)
    |> join(:right, [u, tracks: t], p in assoc(t, :points), as: :points)
    |> group_by([u], u.id)
    |> select([u], %{u | points_received: count(1)})
    |> order_by([u], desc: fragment("count(1)"))
    |> Repo.all()
  end

  @spec count_points(User.t()) :: integer()
  def count_points(%User{} = user) do
    Point
    |> query_for_user(user)
    |> query_for_today()
    |> Repo.aggregate(:count, :id)
  end

  @spec create_point(map()) :: {:ok, Point.t()} | {:error, Ecto.Changeset.t()}
  def create_point(attrs \\ %{}) do
    case %Point{}
    |> Point.changeset(attrs)
    |> Repo.insert() do
      {:ok, point} = res ->
        point
        |> Repo.preload(:track)
        |> Map.get(:track)
        |> Music.broadcast(:point)
        res
      res -> res
    end
  end

  @spec query_for_user(Ecto.Queryable.t(), User.t()) :: Ecto.Queryable.t()
  defp query_for_user(query, %User{id: user_id}) do
    query
    |> join(
      :right, [p],
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
