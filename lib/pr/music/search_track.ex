defmodule PR.Music.SearchTrack do
  defstruct [:name, :artist, :duration, :img, :spotify_id]

  @spec new(map()) :: SearchTrack.t()
  def new(
        %{
          id: id,
          name: name,
          duration_ms: duration,
          artists: [%{name: artist} | _]
        } = params
      ) do
    %__MODULE__{
      name: name,
      artist: artist,
      duration: duration,
      spotify_id: id
    }
    |> Map.merge(get_image(params))
  end

  @spec get_image(map()) :: map()
  defp get_image(%{album: %{images: images}}) do
    case images do
      [_ | [%{url: url} | _]] ->
        %{img: url}

      _ ->
        %{}
    end
  end
end
