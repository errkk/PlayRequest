defmodule PR.Music.Provider.Spotify do
  @behaviour PR.Music.Provider

  alias PR.SpotifyAPI
  alias PR.Music.SearchTrack

  @provider "spotify"

  @impl true
  def search(query) do
    case SpotifyAPI.search(query) do
      {:ok, tracks} -> {:ok, Enum.map(tracks, &SearchTrack.new(&1, @provider))}
      err -> err
    end
  end

  @impl true
  def get_track(external_id) do
    case SpotifyAPI.get_track(external_id) do
      %{} = track_data -> {:ok, SearchTrack.new(track_data, @provider)}
      err -> err
    end
  end

  @impl true
  def replace_playlist(external_ids) do
    external_ids
    |> Enum.map(&("spotify:track:" <> &1))
    |> SpotifyAPI.replace_playlist()
  end

  @impl true
  def favourite_name, do: Application.get_env(:pr, :playlist_name)

  @impl true
  def parse_object_id("spotify:track:" <> external_id), do: {:ok, external_id}
  def parse_object_id(_), do: :no_match
end
