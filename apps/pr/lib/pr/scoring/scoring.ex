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

  def change_point(%Point{} = point) do
    Point.changeset(point, %{})
  end
end
