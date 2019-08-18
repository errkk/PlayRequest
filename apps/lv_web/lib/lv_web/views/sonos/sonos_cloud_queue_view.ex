defmodule EWeb.Sonos.SonosCloudQueueView do
  use EWeb, :view

  def render("context.json", _params) do
    %{
      container: %{
        id: %{
          accountId: "john.musiclover",
          objectId: "music:user:john.musiclover:playlist:5t33Mtrb6rFBqvgz0U2DQe",
          serviceId: "8"
        },
        name: "Liked from Radio",
        service: %{name: "Acme2"},
        type: "playlist"
      },
      contextVersion: "<version-string-for-this-context>",
      queueVersion: "<version-string-for-the-queue>",
      reports: %{sendPlaybackActions: true, sendUpdateAfterMillis: 30000},
      playbackPolicies: %{
        canCrossfade: true,
        canRepeat: false,
        canRepeatOne: false,
        canSeek: true,
        canShuffle: false,
        canSkip: true,
        canSkipBack: true,
        canSkipToItem: true,
        limitedSkips: false,
        showNNextTracks: 10,
        showNPreviousTracks: 10
      }
    }
  end

  def render("item_window.json", _params) do
    %{
      contextVersion: "context_version_string",
      includesBeginningOfQueue: true,
      includesEndOfQueue: false,
      queueVersion: "asdf3cbjal235jazz",
      items: [
        %{
          deleted: false,
          id: "this_is_the_cloud_queue_item_id2",
          policies: %{canCrossfade: false, canSkip: true, isVisible: false},
          track: %{
            durationMillis: 30000,
            id: %{
              accountId: "acct1234",
              objectId: "ab12345",
              serviceId: "ACME Music Service"
            },
            imageUrl: "http://images.example.com/art78956",
            name: "This is a song"
          }
        }
      ]
    }
  end

  def render("version.json", _params) do
    %{
      contextVersion: "context_version_1",
      queueVersion: "queue_version_1"
    }
  end

  def render("time_played.json", _params) do
    %{status: "success"}
  end
end
