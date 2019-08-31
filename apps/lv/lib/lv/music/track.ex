defmodule E.Music.Track do
  defstruct [:name, :artist, :duration, :img]

  @spec new(map()) :: Track.t()
  def new(%{
    name: name,
    duration_ms: duration,
    artists: [%{name: artist} | _]
  } = params) do
    %__MODULE__{
      name: name,
      artist: artist,
      duration: duration,
    }
    |> Map.merge(get_image(params))
  end

  @spec get_image(map()) :: map()
  defp get_image(%{album: %{images: images}}) do
    case images do
      [_ | [%{url: url} | _]] ->
        %{img: url}
      _ -> %{}
    end
  end
end
