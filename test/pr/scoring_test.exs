defmodule PR.ScoringTest do
  use PR.DataCase

  alias PR.Scoring
  alias PR.Scoring.Point
  alias PR.Queue
  alias PR.Queue.Track
  alias PR.Auth.User

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
      insert_list(3, :track, user: player)
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

  describe "deleteyness" do
    test "delete track deletes the points too" do
      point = insert(:point)
      Repo.delete(%Track{id: point.track_id})
      assert [] == Scoring.list_points()
    end

    test "delete point doesn't delete the track" do
      point = insert(:point)
      Repo.delete(%Point{id: point.id})
      assert 1 == Queue.list_tracks() |> length()
    end
  end

  describe "list_top_scorers" do
    test "lists totals for each user with points in the right order" do
      voter = insert(:user)
      player = insert(:user)
      tracks = insert_list(3, :track, user: player)
      Enum.each(tracks, fn track -> insert(:point, track: track, user: voter) end)

      player_id = player.id

      assert [%User{points_received: 3, id: ^player_id}] = Scoring.list_top_scorers()
    end

    test "for today" do
      yesterday = DateTime.utc_now()
      |> Timex.shift(days: -1)
      voter = insert(:user)
      player = insert(:user)
      tracks = insert_list(3, :track, user: player)
      old_tracks = insert_list(3, :track, user: player, inserted_at: yesterday)
      Enum.each(tracks, fn track -> insert(:point, track: track, user: voter) end)
      Enum.each(old_tracks, fn track -> insert(:point, track: track, user: insert(:user)) end)

      player_id = player.id

      assert [%User{points_received: 3, id: ^player_id}] = Scoring.list_top_scorers()
    end
  end
end
