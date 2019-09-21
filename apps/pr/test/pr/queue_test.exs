defmodule PR.QueueTest do
  use PR.DataCase

  alias PR.Queue
  alias PR.Queue.Track

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
end
