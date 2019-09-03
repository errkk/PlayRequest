defmodule PR.Queue do
  @moduledoc """
  The Queue context.
  """

  import Ecto.Query, warn: false
  alias PR.Repo

  alias PR.Queue.Track

  def list_tracks do
    Repo.all(Track)
  end

  def get_track!(id), do: Repo.get!(Track, id)

  def create_track(attrs \\ %{}) do
    %Track{}
    |> Track.changeset(attrs)
    |> Repo.insert()
  end

  def update_track(%Track{} = track, attrs) do
    track
    |> Track.changeset(attrs)
    |> Repo.update()
  end

  def delete_track(%Track{} = track) do
    Repo.delete(track)
  end

  def change_track(%Track{} = track) do
    Track.changeset(track, %{})
  end
end
