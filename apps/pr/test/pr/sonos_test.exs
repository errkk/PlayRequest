defmodule PR.SonosTest do
  use PR.DataCase

  alias PR.Sonos

  describe "tokens" do
    alias PR.Sonos.Auth

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

  describe "houeholds" do
    alias PR.Sonos.Households

    @valid_attrs %{household_id: "some household_id", is_active: true, label: "some label"}
    @update_attrs %{household_id: "some updated household_id", is_active: false, label: "some updated label"}
    @invalid_attrs %{household_id: nil, is_active: nil, label: nil}

    def households_fixture(attrs \\ %{}) do
      {:ok, households} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Sonos.create_households()

      households
    end

    test "list_houeholds/0 returns all houeholds" do
      households = households_fixture()
      assert Sonos.list_houeholds() == [households]
    end

    test "get_households!/1 returns the households with given id" do
      households = households_fixture()
      assert Sonos.get_households!(households.id) == households
    end

    test "create_households/1 with valid data creates a households" do
      assert {:ok, %Households{} = households} = Sonos.create_households(@valid_attrs)
      assert households.household_id == "some household_id"
      assert households.is_active == true
      assert households.label == "some label"
    end

    test "create_households/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Sonos.create_households(@invalid_attrs)
    end

    test "update_households/2 with valid data updates the households" do
      households = households_fixture()
      assert {:ok, %Households{} = households} = Sonos.update_households(households, @update_attrs)
      assert households.household_id == "some updated household_id"
      assert households.is_active == false
      assert households.label == "some updated label"
    end

    test "update_households/2 with invalid data returns error changeset" do
      households = households_fixture()
      assert {:error, %Ecto.Changeset{}} = Sonos.update_households(households, @invalid_attrs)
      assert households == Sonos.get_households!(households.id)
    end

    test "delete_households/1 deletes the households" do
      households = households_fixture()
      assert {:ok, %Households{}} = Sonos.delete_households(households)
      assert_raise Ecto.NoResultsError, fn -> Sonos.get_households!(households.id) end
    end

    test "change_households/1 returns a households changeset" do
      households = households_fixture()
      assert %Ecto.Changeset{} = Sonos.change_households(households)
    end
  end
end
