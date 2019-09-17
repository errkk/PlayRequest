defmodule PR.AuthTest do
  use PR.DataCase

  alias PR.Auth

  describe "users" do
    alias PR.Auth.User

    @valid_attrs %{display_name: "some display_name", email: "some email", first_name: "some first_name", img: "some img", last_name: "some last_name", token: "some token"}
    @update_attrs %{display_name: "some updated display_name", email: "some updated email", first_name: "some updated first_name", img: "some updated img", last_name: "some updated last_name", token: "some updated token"}
    @invalid_attrs %{display_name: nil, email: nil, first_name: nil, img: nil, last_name: nil, token: nil}

    def user_fixture(attrs \\ %{}) do
      {:ok, user} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Auth.create_user()

      user
    end

    test "list_users/0 returns all users" do
      user = user_fixture()
      assert Auth.list_users() == [user]
    end

    test "get_user!/1 returns the user with given id" do
      user = user_fixture()
      assert Auth.get_user!(user.id) == user
    end

    test "create_user/1 with valid data creates a user" do
      assert {:ok, %User{} = user} = Auth.create_user(@valid_attrs)
      assert user.display_name == "some display_name"
      assert user.email == "some email"
      assert user.first_name == "some first_name"
      assert user.img == "some img"
      assert user.last_name == "some last_name"
      assert user.token == "some token"
    end

    test "create_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Auth.create_user(@invalid_attrs)
    end

    test "update_user/2 with valid data updates the user" do
      user = user_fixture()
      assert {:ok, %User{} = user} = Auth.update_user(user, @update_attrs)
      assert user.display_name == "some updated display_name"
      assert user.email == "some updated email"
      assert user.first_name == "some updated first_name"
      assert user.img == "some updated img"
      assert user.last_name == "some updated last_name"
      assert user.token == "some updated token"
    end

    test "update_user/2 with invalid data returns error changeset" do
      user = user_fixture()
      assert {:error, %Ecto.Changeset{}} = Auth.update_user(user, @invalid_attrs)
      assert user == Auth.get_user!(user.id)
    end

    test "delete_user/1 deletes the user" do
      user = user_fixture()
      assert {:ok, %User{}} = Auth.delete_user(user)
      assert_raise Ecto.NoResultsError, fn -> Auth.get_user!(user.id) end
    end

    test "change_user/1 returns a user changeset" do
      user = user_fixture()
      assert %Ecto.Changeset{} = Auth.change_user(user)
    end
  end
end
