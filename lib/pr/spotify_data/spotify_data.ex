defmodule PR.SpotifyData do
  @moduledoc """
  The SpotifyData context.
  """

  import Ecto.Query, warn: false
  alias PR.Repo

  alias PR.SpotifyData.Playlist

  def list_playlists do
    Repo.all(Playlist)
  end

  def get_playlist!(id), do: Repo.get!(Playlist, id)

  def create_playlist(attrs \\ %{}) do
    %Playlist{}
    |> Playlist.changeset(attrs)
    |> Repo.insert()
  end

  def update_playlist(%Playlist{} = playlist, attrs) do
    playlist
    |> Playlist.changeset(attrs)
    |> Repo.update()
  end

  def delete_playlist(%Playlist{} = playlist) do
    Repo.delete(playlist)
  end

  def change_playlist(%Playlist{} = playlist) do
    Playlist.changeset(playlist, %{})
  end
end
