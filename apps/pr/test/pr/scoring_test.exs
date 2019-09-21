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
end
