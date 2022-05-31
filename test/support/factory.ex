defmodule PR.Factory do
  # with Ecto
  use ExMachina.Ecto, repo: PR.Repo


  def user_factory do
    %PR.Auth.User{
      first_name: "Jane",
      last_name: "Jane",
      email: sequence(:email, &"email-#{&1}@gmail.com"),
    }
  end

  def track_factory do
    %PR.Queue.Track{
      name: "Jane's song",
      artist: "Jane",
      duration: 30_000,
      img: "img",
      played_at: nil,
      playing_since: nil,
      spotify_id: sequence(:spotify_id, &"spotify:track:#{&1}"),
      user: insert(:user)
    }
  end

  def group_factory do
    %PR.SonosHouseholds.Group{
      group_id: sequence(:group, &"RINCON:#{&1}"),
      is_active: false
    }
  end

  def played_track_factory do
    struct!(track_factory(), %{
      played_at: DateTime.utc_now()
    })
  end

  def playing_track_factory do
    struct!(track_factory(), %{
      playing_since: DateTime.utc_now() |> DateTime.add(-30, :second)
    })
  end

  def recently_playing_track_factory do
    struct!(track_factory(), %{
      playing_since: DateTime.utc_now() |> DateTime.add(-3, :second)
    })
  end

  def point_factory do
    %PR.Scoring.Point{
      track: build(:track),
      user: build(:user)
    }
  end

  # Build only, these are just maps, to be cast by
  # cast_metadata/1
  def metadata_track_factory(%{id: id}) do
   track = %{
      id: %{object_id: id},
      name: "track name",
      artist: %{name: "artist"},
      duration_millis: 10_000
    }
    %{track: track}
  end

  def metadata_track_factory(%{}) do
    id = sequence(:spotify_id, &"spotify:track:#{&1}")
    metadata_track_factory(%{id: id})
  end

  # Metadata payload after it's converted by the conroller
  def metadata_factory do
    %{
      current_item: build(:metadata_track),
      next_item: build(:metadata_track),
      container: %{type: "playlist"}
    }
  end

  def sonos_error_factory do
    %{errorCode: "Shit's fucked", errorReason: "oh dear"}
  end

  def sonos_play_state_factory do
    %{
      position_millis: 10_000,
      playback_state: :playing
    }
  end
end

