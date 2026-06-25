defmodule PR.Music.SearchTrack do
  defstruct [:name, :artist, :duration, :img, :provider, :external_id, :track_novelty, :artist_novelty]

  @spec new(map(), String.t()) :: SearchTrack.t()
  def new(
        %{
          id: id,
          name: name,
          duration_ms: duration,
          artists: [%{name: artist} | _]
        } = params,
        provider
      ) do
    %__MODULE__{
      name: name,
      artist: artist,
      duration: trunc(duration),
      provider: provider,
      external_id: id
    }
    |> Map.merge(get_image(params))
  end

  def new(%{id: id, title: title, duration: duration, user: user} = params, provider) do
    %__MODULE__{
      name: title,
      artist: Map.get(user, :username),
      duration: trunc(duration),
      provider: provider,
      external_id: to_string(id),
      img: params[:artwork_url] || Map.get(user, :avatar_url)
    }
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
