defmodule PR.Scoring do
  @moduledoc """
  The Scoring context.
  """

  import Ecto.Query, warn: false
  alias PR.Repo

  alias PR.Scoring.Point
  alias PR.Queue.Track
  alias PR.Auth.User

  def list_points do
    Repo.all(Point)
  end

  def create_point(attrs \\ %{}) do
    %Point{}
    |> Point.changeset(attrs)
    |> Repo.insert()
  end

  def change_point(%Point{} = point) do
    Point.changeset(point, %{})
  end
end
