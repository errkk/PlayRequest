defmodule E.SonosTest do
  use E.DataCase

  alias E.Sonos

  describe "tokens" do
    alias E.Sonos.Auth

    @valid_attrs %{access_token: "some access_token", refresh_token: "some refresh_token"}
    @update_attrs %{access_token: "some updated access_token", refresh_token: "some updated refresh_token"}
    @invalid_attrs %{access_token: nil, refresh_token: nil}

    def auth_fixture(attrs \\ %{}) do
      {:ok, auth} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Sonos.create_auth()

      auth
    end

    test "list_tokens/0 returns all tokens" do
      auth = auth_fixture()
      assert Sonos.list_tokens() == [auth]
    end

    test "get_auth!/1 returns the auth with given id" do
      auth = auth_fixture()
      assert Sonos.get_auth!(auth.id) == auth
    end

    test "create_auth/1 with valid data creates a auth" do
      assert {:ok, %Auth{} = auth} = Sonos.create_auth(@valid_attrs)
      assert auth.access_token == "some access_token"
      assert auth.refresh_token == "some refresh_token"
    end

    test "create_auth/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Sonos.create_auth(@invalid_attrs)
    end

    test "update_auth/2 with valid data updates the auth" do
      auth = auth_fixture()
      assert {:ok, %Auth{} = auth} = Sonos.update_auth(auth, @update_attrs)
      assert auth.access_token == "some updated access_token"
      assert auth.refresh_token == "some updated refresh_token"
    end

    test "update_auth/2 with invalid data returns error changeset" do
      auth = auth_fixture()
      assert {:error, %Ecto.Changeset{}} = Sonos.update_auth(auth, @invalid_attrs)
      assert auth == Sonos.get_auth!(auth.id)
    end

    test "delete_auth/1 deletes the auth" do
      auth = auth_fixture()
      assert {:ok, %Auth{}} = Sonos.delete_auth(auth)
      assert_raise Ecto.NoResultsError, fn -> Sonos.get_auth!(auth.id) end
    end

    test "change_auth/1 returns a auth changeset" do
      auth = auth_fixture()
      assert %Ecto.Changeset{} = Sonos.change_auth(auth)
    end
  end
end
