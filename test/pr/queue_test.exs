defmodule PR.QueueTest do
  use PR.DataCase

  alias PR.Queue
  alias PR.Queue.Track
  alias PR.Music.SonosItem
  alias PR.Music.SearchTrack

  describe "list" do
    test "list_unplayed/1 lists in correct order" do
      then =
        DateTime.utc_now()
        |> DateTime.add(-1, :second)

      me = insert(:user)
      track_1_id = insert(:track, inserted_at: then).id
      track_2_id = insert(:track, inserted_at: DateTime.utc_now()).id
      assert [%{id: ^track_1_id}, %{id: ^track_2_id}] = Queue.list_unplayed(me)
    end

    test "list_todays_tracks/1 lists in correct order" do
      then =
        DateTime.utc_now()
        |> DateTime.add(-1, :second)

      me = insert(:user)
      track_1_id = insert(:played_track, inserted_at: then).id
      track_2_id = insert(:played_track, inserted_at: DateTime.utc_now()).id
      _not_me = insert(:track)
      assert [%{id: ^track_1_id}, %{id: ^track_2_id}] = Queue.list_todays_tracks(me)
    end
  end

  describe "clear" do
    test "clear/0 clears unplayed tracks" do
      me = insert(:user)
      track_1_id = insert(:track).id
      track_2_id = insert(:track).id
      Queue.clear()
      assert [] = Queue.list_unplayed(me)
    end
  end

  describe "current_run" do
    test "empty queue returns {nil, []}" do
      assert {nil, []} = Queue.current_run()
    end

    test "all same provider returns the whole queue" do
      t0 = DateTime.add(DateTime.utc_now(), -3, :second)
      insert(:track, provider: "spotify", external_id: "s1", inserted_at: t0)
      insert(:track, provider: "spotify", external_id: "s2", inserted_at: DateTime.add(t0, 1))
      assert {"spotify", ["s1", "s2"]} = Queue.current_run()
    end

    test "returns only the leading same-provider block of a mixed queue" do
      t0 = DateTime.add(DateTime.utc_now(), -5, :second)
      insert(:track, provider: "spotify", external_id: "s1", inserted_at: t0)
      insert(:track, provider: "spotify", external_id: "s2", inserted_at: DateTime.add(t0, 1))
      insert(:track, provider: "soundcloud", external_id: "c1", inserted_at: DateTime.add(t0, 2))
      insert(:track, provider: "spotify", external_id: "s3", inserted_at: DateTime.add(t0, 3))
      assert {"spotify", ["s1", "s2"]} = Queue.current_run()
    end

    test "leading run can be the second provider" do
      t0 = DateTime.add(DateTime.utc_now(), -3, :second)
      insert(:track, provider: "soundcloud", external_id: "c1", inserted_at: t0)
      insert(:track, provider: "spotify", external_id: "s1", inserted_at: DateTime.add(t0, 1))
      assert {"soundcloud", ["c1"]} = Queue.current_run()
    end

    test "ignores played tracks when finding the run head" do
      t0 = DateTime.add(DateTime.utc_now(), -3, :second)
      insert(:played_track, provider: "spotify", external_id: "old", inserted_at: t0)
      insert(:track, provider: "soundcloud", external_id: "c1", inserted_at: DateTime.add(t0, 1))
      assert {"soundcloud", ["c1"]} = Queue.current_run()
    end
  end

  describe "points" do
    test "user sees that they did a point" do
      me = insert(:user)
      track = insert(:track)
      insert(:point, track: track, user: me)
      assert [%Track{points_received: 1, has_pointed: true}] = Queue.list_unplayed(me)
    end

    test "user sees that someone else did points" do
      me = insert(:user)
      track = insert(:track)
      insert_list(2, :point, track: track)
      assert [%Track{points_received: 2, has_pointed: false}] = Queue.list_unplayed(me)
    end
  end

  describe "queuing" do
    test "can't queue something twice if its unplayed" do
      me = insert(:user)
      insert(:track, external_id: "derp", played_at: nil, playing_since: nil)
      params = params_for(:track, external_id: "derp", user_id: me.id)

      assert {:error, %{errors: errors}} = Queue.create_track(params)
      assert {:external_id, {"Already queued", _}} = errors |> Enum.at(0)
    end

    test "can't queue something twice if its playing and marked unplayed" do
      me = insert(:user)

      insert(:track, external_id: "derp", played_at: nil, playing_since: DateTime.utc_now())

      params = params_for(:track, external_id: "derp", user_id: me.id)

      assert {:error, %{errors: errors}} = Queue.create_track(params)
      assert {:external_id, {"Already queued", _}} = errors |> Enum.at(0)
    end

    test "can queue same track if it's been played" do
      me = insert(:user)

      insert(:track, external_id: "derp", played_at: DateTime.utc_now())

      params = params_for(:track, external_id: "derp", user_id: me.id)

      assert {:ok, track} = Queue.create_track(params)
    end
  end

  describe "playing" do
    test "set playing since" do
      current_track = insert(:track, external_id: "derp")

      assert {:ok, [played: nil, playing: 1]} =
               Queue.set_current(%SonosItem{provider: "spotify", external_id: "derp"})

      refute Track |> Repo.get(current_track.id) |> Map.get(:playing_since) |> is_nil()
    end

    test "set playing since and played at" do
      previous_track = insert(:track, external_id: "herp", playing_since: ~N[2019-01-01 00:00:00])
      current_track = insert(:track, external_id: "derp")

      assert {:ok, [played: 1, playing: 1]} =
               Queue.set_current(%SonosItem{provider: "spotify", external_id: "derp"})

      assert %{external_id: "derp"} = Queue.get_playing()
      refute Track |> Repo.get(previous_track.id) |> Map.get(:played_at) |> is_nil()
      assert Track |> Repo.get(previous_track.id) |> Map.get(:playing_since) |> is_nil()
      refute Track |> Repo.get(current_track.id) |> Map.get(:playing_since) |> is_nil()
    end

    test "nothing is playing, track that ran its course is marked played" do
      previous_track =
        insert(:track,
          external_id: "herp",
          playing_since: ~N[2019-01-01 00:10:00],
          duration: 10_000
        )

      assert {:ok, [played: 1, playing: nil]} = Queue.set_current(%{})
      assert Queue.get_playing() |> is_nil()
      refute Track |> Repo.get(previous_track.id) |> Map.get(:played_at) |> is_nil()
      assert Track |> Repo.get(previous_track.id) |> Map.get(:playing_since) |> is_nil()
    end

    test "nothing is playing, track that barely started goes back in the queue" do
      track = insert(:recently_playing_track, external_id: "herp", duration: 30_000)
      assert {:ok, [played: nil, playing: nil]} = Queue.set_current(%{})
      assert %{played_at: nil, playing_since: nil} = Queue.get_track!(track.id)
    end

    test "new track, previous track that barely started goes back in the queue" do
      previous_track = insert(:recently_playing_track, external_id: "herp", duration: 30_000)
      insert(:track, external_id: "derp")

      assert {:ok, [played: nil, playing: 1]} =
               Queue.set_current(%SonosItem{provider: "spotify", external_id: "derp"})

      assert %{external_id: "derp"} = Queue.get_playing()
      assert %{played_at: nil, playing_since: nil} = Queue.get_track!(previous_track.id)
    end

    test "bump marks a track that barely started as played" do
      track = insert(:recently_playing_track, external_id: "herp", duration: 30_000)
      assert {1, nil} = Queue.bump()
      assert %{playing_since: nil, played_at: %DateTime{}} = Queue.get_track!(track.id)
    end

    test "already played" do
      played_track = insert(:track, external_id: "herp", played_at: ~N[2019-01-01 00:00:00])

      assert {:ok, [played: nil, playing: nil]} =
               Queue.set_current(%SonosItem{provider: "spotify", external_id: "herp"})

      assert Queue.get_playing() |> is_nil()
      refute Track |> Repo.get(played_track.id) |> Map.get(:played_at) |> is_nil()
      assert Track |> Repo.get(played_track.id) |> Map.get(:playing_since) |> is_nil()
    end

    test "same thing already playing" do
      {:ok, playing_since} = ~N[2019-01-01 00:00:00] |> DateTime.from_naive("Etc/UTC")
      insert(:track, external_id: "herple", played_at: ~N[2018-01-01 00:00:00])
      current_track = insert(:track, external_id: "herp", playing_since: playing_since)

      assert {:ok, [played: nil, playing: nil]} =
               Queue.set_current(%SonosItem{provider: "spotify", external_id: "herp"})

      assert %{external_id: "herp"} = Queue.get_playing()
      track = Track |> Repo.get(current_track.id)
      assert track |> Map.get(:played_at) |> is_nil()
      assert DateTime.compare(track.playing_since, playing_since) === :eq
    end
  end

  describe "requeue_errored" do
    test "errored track goes back in the queue with its error counted" do
      track = insert(:recently_playing_track, name: "Flaky")
      assert :requeued = Queue.requeue_errored("Flaky")
      assert %{playing_since: nil, played_at: nil, error_count: 1} = Queue.get_track!(track.id)
    end

    test "track that keeps erroring is dropped" do
      track = insert(:recently_playing_track, name: "Flaky", error_count: 2)
      assert :dropped = Queue.requeue_errored("Flaky")

      assert %{playing_since: nil, played_at: %DateTime{}, error_count: 3} =
               Queue.get_track!(track.id)
    end

    test "leaves the playing track alone if the error is for a different track" do
      track = insert(:recently_playing_track, name: "Fine")
      assert :not_playing = Queue.requeue_errored("Flaky")

      assert %{playing_since: %DateTime{}, played_at: nil, error_count: 0} =
               Queue.get_track!(track.id)
    end

    test "nothing playing" do
      assert :not_playing = Queue.requeue_errored("Flaky")
    end
  end

  describe "participation" do
    test "has_participated?/1 is true when user has queued something" do
      user = insert(:user)
      insert(:track, user: user)
      assert Queue.has_participated?(user)
    end

    test "has_participated?/1 is false when user hasn't queued something" do
      user = insert(:user)
      refute Queue.has_participated?(user)
    end
  end

  describe "novelty" do
    test "get_novelty_for_search_results/1 scores each result by its own id" do
      insert(:played_track, external_id: "played-id", artist: "Played Artist")

      results = [
        search_track(external_id: "brand-new-id", artist: "Brand New Artist"),
        search_track(external_id: "played-id", artist: "Played Artist")
      ]

      assert [
               %{external_id: "brand-new-id", track_novelty: 100, artist_novelty: 100},
               %{external_id: "played-id", track_novelty: 0, artist_novelty: 0}
             ] = Queue.get_novelty_for_search_results(results)
    end

    test "get_novelty_for_search_results/1 matches artist novelty when the track is new" do
      insert(:played_track, external_id: "played-id", artist: "Known Artist")

      results = [search_track(external_id: "different-id", artist: "Known Artist")]

      assert [%{track_novelty: 100, artist_novelty: 0}] =
               Queue.get_novelty_for_search_results(results)
    end

    test "get_novelty_for_search_results/1 scopes track novelty by provider" do
      insert(:played_track,
        external_id: "shared-id",
        provider: "spotify",
        artist: "Spotify Artist"
      )

      results = [
        search_track(
          external_id: "shared-id",
          provider: "soundcloud",
          artist: "SoundCloud Artist"
        )
      ]

      assert [%{track_novelty: 100, artist_novelty: 100}] =
               Queue.get_novelty_for_search_results(results)
    end

    test "get_novelty_for_search_results/1 handles no search results" do
      assert [] = Queue.get_novelty_for_search_results([])
    end

    test "get_novelty_for_search_results/1 handles a result with no artist" do
      results = [search_track(external_id: "no-artist-id", artist: nil)]

      assert [%{track_novelty: 100, artist_novelty: 100}] =
               Queue.get_novelty_for_search_results(results)
    end

    test "list_unplayed/1 scopes track novelty by provider" do
      me = insert(:user)

      insert(:played_track,
        external_id: "shared-id",
        provider: "spotify",
        artist: "Spotify Artist"
      )

      unplayed =
        insert(:track,
          external_id: "shared-id",
          provider: "soundcloud",
          artist: "SoundCloud Artist"
        )

      unplayed_id = unplayed.id
      assert [%{id: ^unplayed_id, track_novelty: 100}] = Queue.list_unplayed(me)
    end
  end

  defp search_track(attrs) do
    struct!(
      %SearchTrack{
        name: "Jane's song",
        artist: "Jane",
        duration: 30_000,
        img: "img",
        provider: "spotify",
        external_id: "track-x"
      },
      attrs
    )
  end
end
