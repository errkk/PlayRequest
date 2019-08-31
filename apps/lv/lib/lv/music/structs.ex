defmodule E.Music.Track do
  defstruct [:name, :artist, :duration]

  @spec new(map()) :: Track.t()
  def new(%{name: name, artists: [%{name: artist} | _]}) do
    %__MODULE__{
      name: name,
      artist: artist
    }
  end
end
