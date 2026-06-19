defmodule PR.ExternalAuthTest do
  use PR.DataCase

  alias PR.ExternalAuth
  alias PR.ExternalAuth.Auth

  describe "discard_auth/1" do
    test "deletes the stored token for a service given as a string" do
      insert(:auth, service: "Elixir.PR.SpotifyAPI")

      assert {:ok, %Auth{}} = ExternalAuth.discard_auth("Elixir.PR.SpotifyAPI")
      assert is_nil(ExternalAuth.get_auth("Elixir.PR.SpotifyAPI"))
    end

    test "deletes the stored token for a service given as a module atom" do
      insert(:auth, service: "Elixir.PR.SpotifyAPI")

      assert {:ok, %Auth{}} = ExternalAuth.discard_auth(PR.SpotifyAPI)
      assert is_nil(ExternalAuth.get_auth(PR.SpotifyAPI))
    end

    test "is a no-op when there is no token to discard" do
      assert {:ok, nil} = ExternalAuth.discard_auth(PR.SpotifyAPI)
    end
  end
end
