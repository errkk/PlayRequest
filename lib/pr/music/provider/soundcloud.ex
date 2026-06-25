defmodule PR.Music.Provider.SoundCloud do
  @behaviour PR.Music.Provider

  alias PR.SoundCloudAPI
  alias PR.Music.SearchTrack

  @provider "soundcloud"

  @impl true
  def search(query) do
    case SoundCloudAPI.search(query) do
      {:ok, tracks} -> {:ok, Enum.map(tracks, &SearchTrack.new(&1, @provider))}
      err -> err
    end
  end

  @impl true
  def get_track(external_id) do
    case SoundCloudAPI.get_track(external_id) do
      %{id: _} = track_data -> {:ok, SearchTrack.new(track_data, @provider)}
      err -> err
    end
  end

  @impl true
  def replace_playlist(external_ids) do
    SoundCloudAPI.replace_playlist(external_ids)
  end

  @impl true
  def favourite_name, do: Application.get_env(:pr, :soundcloud_playlist_name)

  # Sonos metadata object_id for a SoundCloud track. Confirmed from a live
  # metadata webhook: Sonos wraps the track urn in its universalMusicObjectId
  # format, e.g. "track->soundcloud:tracks:59547812".
  @impl true
  def parse_object_id("track->soundcloud:tracks:" <> external_id), do: {:ok, external_id}
  def parse_object_id("soundcloud:tracks:" <> external_id), do: {:ok, external_id}
  def parse_object_id(_), do: :no_match
end
