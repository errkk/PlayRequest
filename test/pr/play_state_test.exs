defmodule PR.PlayStateTest do
  use PR.DataCase
  import Mock

  alias PR.Queue
  alias PR.Queue.Track
  alias PR.Music.SonosItem
  alias PR.PlayState

  # This is the bit that gets called after the group is verified
  # and the payload is converted to atoms. But that's all
  describe "process_metadata/1" do

    setup_with_mocks([
      {DateTime, [:passthrough], utc_now: fn -> ~U[2022-01-01 00:00:00Z] end},
    ]) do
      {:ok, %{mocked_now: ~U[2022-01-01 00:00:00Z]}}
    end

    test "updates playing track from metadata", %{mocked_now: now} do
      spotify_track_id = "123"
      spotify_id = "spotify:track:#{spotify_track_id}"
      queue_track = insert(:track, spotify_id: spotify_track_id)
      metadata = build(:metadata, current_item: build(:metadata_track, id: spotify_id))

      # Act
      PlayState.process_metadata(metadata)

      # Assert
      %{playing_since: playing_since, played_at: played_at} = Queue.get_track!(queue_track.id)
      assert is_nil(played_at)
      refute is_nil(playing_since)

      # Check agent state
      assert %{current_item: %SonosItem{spotify_id: ^spotify_track_id}}
        = PlayState.get(:metadata)
    end

    test "updates playing track, marks last track played from metadata", %{mocked_now: now} do
      spotify_track_id = "123"
      spotify_id = "spotify:track:#{spotify_track_id}"

      previous_track = insert(:playing_track)
      queue_track = insert(:track, spotify_id: spotify_track_id)
      metadata = build(:metadata, current_item: build(:metadata_track, id: spotify_id))

      # Act
      PlayState.process_metadata(metadata)

      # Assert
      %{playing_since: playing_since, played_at: played_at} = Queue.get_track!(queue_track.id)
      assert is_nil(played_at)
      refute is_nil(playing_since)
      assert playing_since == now 

      %{playing_since: playing_since, played_at: played_at} = Queue.get_track!(previous_track.id)
      refute is_nil(played_at)
      assert is_nil(playing_since)
      assert played_at == now

      # Check agent state
      assert %{current_item: %SonosItem{spotify_id: ^spotify_track_id}}
        = PlayState.get(:metadata)
    end

    test "error mode, dont update track when it says playing nothing", %{mocked_now: now} do
      spotify_track_id = "123"
      spotify_id = "spotify:track:#{spotify_track_id}"

      previous_track = insert(:playing_track)
      # Metadata says playing nothing
      metadata = build(:metadata, current_item: %{})
      sonos_error = build(:sonos_error)

      # Act

      # This updates the error mode on the agent, which interferes with other tests
      # PlayState.process_sonos_error(sonos_error)
      PlayState.process_metadata(metadata)

      # Assert
      %{playing_since: playing_since, played_at: played_at} = Queue.get_track!(previous_track.id)
      # This should not be set to played
      assert is_nil(played_at)
      assert is_nil(playing_since)

      # Check agent state
      assert PlayState.get(:error_mode)

      # Ok it's ok now we recieve a playing playstate
      playing = build(:sonos_play_state)
      PlayState.process_play_state(playing)

      %{playing_since: playing_since, played_at: played_at} = Queue.get_track!(previous_track.id)
      # This should not be set to played
      assert is_nil(played_at)
      refute is_nil(playing_since)

      # Check agent state
      refute PlayState.get(:error_mode)
    end

    # This might be a bit rare, cos it will probs just say in metadata that the
    # current item is the first thing in the queue, from ages ago, but the play state is idle
    test "no track playing on sonos, 2 tracks in queue, one is playing" do
      spotify_track_id = "123"
      spotify_id = "spotify:track:#{spotify_track_id}"

      previous_track = insert(:playing_track)
      queue_track = insert(:track, spotify_id: spotify_track_id)
      metadata = build(:metadata, current_item: %{}, next_item: %{})

      # Act
      PlayState.process_metadata(metadata)

      # Assert
      %{playing_since: playing_since, played_at: played_at} = Queue.get_track!(queue_track.id)
      assert is_nil(played_at)
      assert is_nil(playing_since)

      %{playing_since: playing_since, played_at: played_at} = Queue.get_track!(previous_track.id)
      # The playing track is marked as played if it was started > 20 seconds ago
      refute is_nil(played_at)
      assert is_nil(playing_since)

      # Check agent state
      assert %{current_item: %{}} = PlayState.get(:metadata)
    end

    test "no track playing on sonos, 2 tracks in queue, one is playing since < 20 sec" do
      spotify_track_id = "123"
      spotify_id = "spotify:track:#{spotify_track_id}"

      previous_track = insert(:recently_playing_track)
      queue_track = insert(:track, spotify_id: spotify_track_id)
      metadata = build(:metadata, current_item: %{}, next_item: %{})

      # Act
      PlayState.process_metadata(metadata)

      # Assert
      %{playing_since: playing_since, played_at: played_at} = Queue.get_track!(queue_track.id)
      assert is_nil(played_at)
      assert is_nil(playing_since)

      %{playing_since: playing_since, played_at: played_at} = Queue.get_track!(previous_track.id)
      # The playnig track is marked as not played nor playing
      assert is_nil(played_at)
      assert is_nil(playing_since)

      # Check agent state
      assert %{current_item: %{}} = PlayState.get(:metadata)
    end

    # When it finishes, current track will not be in DB queue
    # Playstate will be idle (or soon)
    # If there are tracks, then they should be triggered
    test "current item is first track in sonos queue, so no tracks in DB queue are playing" do
      spotify_track_id = "123"
      spotify_id = "spotify:track:#{spotify_track_id}"

      queue_track = insert(:track, spotify_id: spotify_track_id)
      current_item_from_ages_ago = build(:metadata_track)
      metadata = build(:metadata, current_item: current_item_from_ages_ago, next_item: %{})

      # Act
      PlayState.process_metadata(metadata)

      # Assert
      %{playing_since: playing_since, played_at: played_at} = Queue.get_track!(queue_track.id)
      assert is_nil(played_at)
      assert is_nil(playing_since)

      # Check agent state
      assert %{current_item: %{}} = PlayState.get(:metadata)
    end

    test "current item is first track in sonos queue, but one track in queue thinks it's playing" do
      spotify_track_id = "123"
      spotify_id = "spotify:track:#{spotify_track_id}"

      queue_track = insert(:playing_track, spotify_id: spotify_track_id)
      current_item_from_ages_ago = build(:metadata_track)
      metadata = build(:metadata, current_item: current_item_from_ages_ago, next_item: %{})

      # Act
      PlayState.process_metadata(metadata)

      # Assert
      %{playing_since: playing_since, played_at: played_at} = Queue.get_track!(queue_track.id)
      refute is_nil(played_at)
      assert is_nil(playing_since)

      # Check agent state
      assert %{current_item: %{}} = PlayState.get(:metadata)
    end
  end

  describe "process_playstate/1" do
  end
end
