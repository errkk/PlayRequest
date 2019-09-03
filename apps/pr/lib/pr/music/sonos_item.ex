defmodule PR.Music.SonosItem do
  defstruct [:name, :artist, :duration, :spotify_id]

  @spec new(map()) :: SonosItem.t()
  def new(%{
    track: %{
      id: %{object_id: spotify_id},
      name: name,
      artist: %{name: artist},
      duration_millis: duration
    }
  } = params) do
    %__MODULE__{
      name: name,
      artist: artist,
      duration: duration,
      spotify_id: spotify_id
    }
  end
end
