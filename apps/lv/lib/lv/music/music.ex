defmodule E.Music do
  alias E.SpotifyAPI
  alias E.Music.Track

  @spec search(String.t()) :: {:ok, [Track.t()]} | {:error}
  def search(q) do
    case SpotifyAPI.search(q) do
      {:ok, tracks} ->
        tracks =
          tracks
          |> Enum.map(&Track.new/1)
          {:ok, tracks}
      err -> err
    end
  end
end
