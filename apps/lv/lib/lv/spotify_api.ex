defmodule E.SpotifyAPI do
  def get_auth_link!, do: Spotify.Authorization.url()

end
