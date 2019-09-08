defmodule PR.Music.SonosItem do
  defstruct [:name, :artist, :duration, :spotify_id, :spotify_uri]

  @spec new(map()) :: SonosItem.t()
  def new(%{
    track: %{
      id: %{object_id: "spotify:track:" <> spotify_id},
      name: name,
      artist: %{name: artist},
      duration_millis: duration
    }
  } = params) do
    %__MODULE__{
      name: name,
      artist: artist,
      duration: duration,
      spotify_uri: "spotify:track:" <> spotify_id,
      spotify_id: spotify_id
    }
  end
end