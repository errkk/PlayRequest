defmodule PR.ScoringTest do
  use PR.DataCase

  alias PR.Scoring

  describe "points" do
    test "can save a point for someone elses track" do
      track = insert(:track)
      voter = insert(:user)
      assert {:ok, _} = Scoring.create_point(%{track_id: track.id, user_id: voter.id})
    end

    test "can't save a point for the same track twice" do
      track = insert(:track)
      voter = insert(:user)
      assert {:ok, _} = Scoring.create_point(%{track_id: track.id, user_id: voter.id})
      assert {:error, _} = Scoring.create_point(%{track_id: track.id, user_id: voter.id})
    end

    test "can't save a point own track" do
      me = insert(:user)
      track = insert(:track, user: me)
      assert {:error, _} = Scoring.create_point(%{track_id: track.id, user_id: me.id})
    end
  end

  describe "aggregates" do
    test "countts points for tracks of the user" do
      voter = insert(:user)
      player = insert(:user)
      tracks = insert_list(3, :track, user: player)
      Enum.each(tracks, fn track -> insert(:point, track: track, user: voter) end)

      insert_list(3, :point)

      assert 3 == Scoring.count_points(player)
    end

    test "its ok to has no points" do
      player = insert(:user)
      tracks = insert_list(3, :track, user: player)
      insert_list(3, :point)

      assert 0 == Scoring.count_points(player)
    end

    test "old news" do
      voter = insert(:user)
      player = insert(:user)
      tracks = insert_list(3, :track, user: player)
      Enum.each(tracks, fn track -> insert(:point, track: track, user: voter, inserted_at: ~N[2019-01-01 00:00:00]) end)

      insert_list(3, :point)

      assert 0 == Scoring.count_points(player)
    end
  end
end
