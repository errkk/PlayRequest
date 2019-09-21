defmodule PR.ScoringTest do
  use PR.DataCase

  alias PR.Scoring

  describe "points" do
    alias PR.Scoring.Point

    @valid_attrs %{}
    @update_attrs %{}
    @invalid_attrs %{}

    def point_fixture(attrs \\ %{}) do
      {:ok, point} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Scoring.create_point()

      point
    end

    test "list_points/0 returns all points" do
      point = point_fixture()
      assert Scoring.list_points() == [point]
    end

    test "get_point!/1 returns the point with given id" do
      point = point_fixture()
      assert Scoring.get_point!(point.id) == point
    end

    test "create_point/1 with valid data creates a point" do
      assert {:ok, %Point{} = point} = Scoring.create_point(@valid_attrs)
    end

    test "create_point/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Scoring.create_point(@invalid_attrs)
    end

    test "update_point/2 with valid data updates the point" do
      point = point_fixture()
      assert {:ok, %Point{} = point} = Scoring.update_point(point, @update_attrs)
    end

    test "update_point/2 with invalid data returns error changeset" do
      point = point_fixture()
      assert {:error, %Ecto.Changeset{}} = Scoring.update_point(point, @invalid_attrs)
      assert point == Scoring.get_point!(point.id)
    end

    test "delete_point/1 deletes the point" do
      point = point_fixture()
      assert {:ok, %Point{}} = Scoring.delete_point(point)
      assert_raise Ecto.NoResultsError, fn -> Scoring.get_point!(point.id) end
    end

    test "change_point/1 returns a point changeset" do
      point = point_fixture()
      assert %Ecto.Changeset{} = Scoring.change_point(point)
    end
  end
end
