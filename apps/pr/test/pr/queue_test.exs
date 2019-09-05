defmodule PR.QueueTest do
  use PR.DataCase

  alias PR.Queue

  describe "tracks" do
    alias PR.Queue.Track

    @valid_attrs %{artist: "some artist", duration: 42, img: "some img", spotify_id: "some spotify_id", title: "some title"}
    @update_attrs %{artist: "some updated artist", duration: 43, img: "some updated img", spotify_id: "some updated spotify_id", title: "some updated title"}
    @invalid_attrs %{artist: nil, duration: nil, img: nil, spotify_id: nil, title: nil}

    def track_fixture(attrs \\ %{}) do
      {:ok, track} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Queue.create_track()

      track
    end

    test "list_tracks/0 returns all tracks" do
      track = track_fixture()
      assert Queue.list_tracks() == [track]
    end

    test "get_track!/1 returns the track with given id" do
      track = track_fixture()
      assert Queue.get_track!(track.id) == track
    end

    test "create_track/1 with valid data creates a track" do
      assert {:ok, %Track{} = track} = Queue.create_track(@valid_attrs)
      assert track.artist == "some artist"
      assert track.duration == 42
      assert track.img == "some img"
      assert track.spotify_id == "some spotify_id"
      assert track.title == "some title"
    end

    test "create_track/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Queue.create_track(@invalid_attrs)
    end

    test "update_track/2 with valid data updates the track" do
      track = track_fixture()
      assert {:ok, %Track{} = track} = Queue.update_track(track, @update_attrs)
      assert track.artist == "some updated artist"
      assert track.duration == 43
      assert track.img == "some updated img"
      assert track.spotify_id == "some updated spotify_id"
      assert track.title == "some updated title"
    end

    test "update_track/2 with invalid data returns error changeset" do
      track = track_fixture()
      assert {:error, %Ecto.Changeset{}} = Queue.update_track(track, @invalid_attrs)
      assert track == Queue.get_track!(track.id)
    end

    test "delete_track/1 deletes the track" do
      track = track_fixture()
      assert {:ok, %Track{}} = Queue.delete_track(track)
      assert_raise Ecto.NoResultsError, fn -> Queue.get_track!(track.id) end
    end

    test "change_track/1 returns a track changeset" do
      track = track_fixture()
      assert %Ecto.Changeset{} = Queue.change_track(track)
    end
  end
end
