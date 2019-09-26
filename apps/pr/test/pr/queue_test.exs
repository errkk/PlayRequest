defmodule PR.QueueTest do
  use PR.DataCase

  alias PR.Queue
  alias PR.Queue.Track
  alias PR.Music.SonosItem

  describe "points" do
    test "user sees that they did a point" do
      me = insert(:user)
      track = insert(:track, user: me)
      assert [track] = Queue.list_unplayed(me)
      assert %Track{points: 1, has_pointed: true}
    end

    test "user sees that someone else did points" do
      me = insert(:user)
      track = insert(:track)
      insert_list(2, :point, track: track)
      assert [track] = Queue.list_unplayed(me)
      assert %Track{points: 2, has_pointed: false} = track
    end
  end

  describe "queuing" do
    test "can't queue something twice if its unplayed" do
      me = insert(:user)
      track = insert(:track, user: me, spotify_id: "derp")
      assert {:error, _} = Queue.create_track(%{user_id: me.id, spotify_id: "derp"})
    end
  end

  describe "playing" do
    test "set playing since" do
      current_track = insert(:track, spotify_id: "derp")
      assert {:started, _} = Queue.set_current(%SonosItem{spotify_id: "derp"})
      refute Track |> Repo.get(current_track.id) |> Map.get(:playing_since) |> is_nil()
    end

    test "set playing since and played at" do
      previous_track = insert(:track, spotify_id: "herp", playing_since: ~N[2019-01-01 00:00:00])
      current_track = insert(:track, spotify_id: "derp")
      assert {:started, _} = Queue.set_current(%SonosItem{spotify_id: "derp"})
      assert %{spotify_id: "derp"} = Queue.get_playing()
      refute Track |> Repo.get(previous_track.id) |> Map.get(:played_at) |> is_nil()
      assert Track |> Repo.get(previous_track.id) |> Map.get(:playing_since) |> is_nil()
      refute Track |> Repo.get(current_track.id) |> Map.get(:playing_since) |> is_nil()
    end

    test "nothing is playing" do
      previous_track = insert(:track, spotify_id: "herp", playing_since: ~N[2019-01-01 00:00:00])
      assert {:ok} = Queue.set_current(%{})
      assert Queue.get_playing() |> is_nil()
      refute Track |> Repo.get(previous_track.id) |> Map.get(:played_at) |> is_nil()
      assert Track |> Repo.get(previous_track.id) |> Map.get(:playing_since) |> is_nil()
    end

    test "already played" do
      played_track = insert(:track, spotify_id: "herp", played_at: ~N[2019-01-01 00:00:00])
      assert {:ok} = Queue.set_current(%SonosItem{spotify_id: "herp"})
      assert Queue.get_playing() |> is_nil()
      refute Track |> Repo.get(played_track.id) |> Map.get(:played_at) |> is_nil()
      assert Track |> Repo.get(played_track.id) |> Map.get(:playing_since) |> is_nil()
    end

    test "same thing already playing" do
      {:ok, playing_since} = ~N[2019-01-01 00:00:00] |> DateTime.from_naive("Etc/UTC")
      insert(:track, spotify_id: "herple", played_at: ~N[2018-01-01 00:00:00])
      current_track = insert(:track, spotify_id: "herp", playing_since: playing_since)
      assert {:already_started, ^playing_since} = Queue.set_current(%SonosItem{spotify_id: "herp"})
      assert %{spotify_id: "herp"} = Queue.get_playing()
      track = Track |> Repo.get(current_track.id)
      assert track |> Map.get(:played_at) |> is_nil()
      assert DateTime.compare(track.playing_since, playing_since) === :eq
    end
  end
end
