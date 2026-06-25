defmodule PR.Music.Provider do
  @moduledoc """
  Behaviour for a streaming-service provider. The queue and playback pipeline
  talk to this rather than to a specific service, so a new service is added by
  implementing the callbacks and registering the module in `@providers`.
  """

  alias PR.Music.SearchTrack

  @callback search(query :: String.t()) :: {:ok, [SearchTrack.t()]} | {:error, term()}
  @callback get_track(external_id :: String.t()) :: {:ok, SearchTrack.t()} | {:error, term()}
  @callback replace_playlist(external_ids :: [String.t()]) :: {:ok, term()} | {:error, term()}
  @callback favourite_name() :: String.t()

  # The Sonos metadata object_id for a track, e.g. "spotify:track:" <> id
  @callback parse_object_id(object_id :: String.t()) ::
              {:ok, external_id :: String.t()} | :no_match

  @providers %{
    "spotify" => PR.Music.Provider.Spotify,
    "soundcloud" => PR.Music.Provider.SoundCloud
  }

  @spec for(String.t()) :: module()
  def for(provider), do: Map.fetch!(@providers, provider)

  @spec default() :: String.t()
  def default, do: Application.get_env(:pr, :default_provider)

  @spec all() :: [String.t()]
  def all, do: Map.keys(@providers)

  @doc "Find the provider that recognises a Sonos object_id."
  @spec match_object_id(String.t()) :: {:ok, provider :: String.t(), external_id :: String.t()} | :no_match
  def match_object_id(object_id) do
    Enum.find_value(@providers, :no_match, fn {provider, mod} ->
      case mod.parse_object_id(object_id) do
        {:ok, external_id} -> {:ok, provider, external_id}
        :no_match -> nil
      end
    end)
  end
end
