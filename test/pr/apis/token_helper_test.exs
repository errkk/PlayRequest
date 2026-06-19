defmodule PR.Apis.TokenHelperTest do
  use PR.DataCase
  import Mock

  alias OAuth2.{AccessToken, Client, Response}
  alias PR.Apis.TokenHelper
  alias PR.ExternalAuth
  alias PR.SpotifyAPI

  describe "invalid_grant?/1" do
    test "true for a decoded error map" do
      assert TokenHelper.invalid_grant?(%{"error" => "invalid_grant"})
    end

    test "true for a raw JSON error body" do
      assert TokenHelper.invalid_grant?(~s({"error":"invalid_grant","error_description":"expired"}))
    end

    test "false for other errors" do
      refute TokenHelper.invalid_grant?(%{"error" => "invalid_client"})
      refute TokenHelper.invalid_grant?(~s({"error":"server_error"}))
      refute TokenHelper.invalid_grant?(nil)
    end
  end

  describe "get_refresh_token/0 when the refresh token has expired" do
    setup do
      Agent.update(SpotifyAPI, fn _ -> nil end)
      insert(:auth, service: "Elixir.PR.SpotifyAPI")
      :ok
    end

    test "discards the stored token and signals reauth is required" do
      response = {:error, %Response{status_code: 400, body: ~s({"error":"invalid_grant"})}}

      with_mock Client, [:passthrough], get_token: fn _client -> response end do
        assert {:error, :invalid_grant} = SpotifyAPI.get_refresh_token()
      end

      assert is_nil(ExternalAuth.get_auth(SpotifyAPI))
    end
  end

  describe "get_refresh_token/0 on a successful refresh" do
    setup do
      Agent.update(SpotifyAPI, fn _ -> nil end)
      insert(:auth, service: "Elixir.PR.SpotifyAPI", access_token: "old")
      :ok
    end

    test "stores the new token" do
      token = %AccessToken{access_token: ~s({"access_token":"new","refresh_token":"newref"})}
      response = {:ok, %Client{token: token}}

      with_mock Client, [:passthrough], get_token: fn _client -> response end do
        assert {:ok} = SpotifyAPI.get_refresh_token()
      end

      assert %{access_token: "new"} = ExternalAuth.get_auth(SpotifyAPI)
    end
  end
end
