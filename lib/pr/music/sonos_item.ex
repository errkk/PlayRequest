defmodule PR.Music.SonosItem do
  alias PR.Music.Provider

  defstruct [:name, :artist, :duration, :provider, :external_id, :object_id, playing_since: nil]

  @spec new(map()) :: SonosItem.t()
  def new(%{
        track: %{
          id: %{object_id: object_id},
          name: name,
          artist: %{name: artist},
          duration_millis: duration
        }
      }) do
    {:ok, provider, external_id} = Provider.match_object_id(object_id)

    %__MODULE__{
      name: name,
      artist: artist,
      duration: duration,
      provider: provider,
      external_id: external_id,
      object_id: object_id
    }
  end
end
