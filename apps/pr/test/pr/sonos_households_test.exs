defmodule PR.SonosHouseholdsTest do
  use PR.DataCase

  alias PR.SonosHouseholds

  describe "players" do
    alias PR.SonosHouseholds.Players

    @valid_attrs %{label: "some label", player_id: "some player_id"}
    @update_attrs %{label: "some updated label", player_id: "some updated player_id"}
    @invalid_attrs %{label: nil, player_id: nil}

    def players_fixture(attrs \\ %{}) do
      {:ok, players} =
        attrs
        |> Enum.into(@valid_attrs)
        |> SonosHouseholds.create_players()

      players
    end

    test "list_players/0 returns all players" do
      players = players_fixture()
      assert SonosHouseholds.list_players() == [players]
    end

    test "get_players!/1 returns the players with given id" do
      players = players_fixture()
      assert SonosHouseholds.get_players!(players.id) == players
    end

    test "create_players/1 with valid data creates a players" do
      assert {:ok, %Players{} = players} = SonosHouseholds.create_players(@valid_attrs)
      assert players.label == "some label"
      assert players.player_id == "some player_id"
    end

    test "create_players/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = SonosHouseholds.create_players(@invalid_attrs)
    end

    test "update_players/2 with valid data updates the players" do
      players = players_fixture()
      assert {:ok, %Players{} = players} = SonosHouseholds.update_players(players, @update_attrs)
      assert players.label == "some updated label"
      assert players.player_id == "some updated player_id"
    end

    test "update_players/2 with invalid data returns error changeset" do
      players = players_fixture()
      assert {:error, %Ecto.Changeset{}} = SonosHouseholds.update_players(players, @invalid_attrs)
      assert players == SonosHouseholds.get_players!(players.id)
    end

    test "delete_players/1 deletes the players" do
      players = players_fixture()
      assert {:ok, %Players{}} = SonosHouseholds.delete_players(players)
      assert_raise Ecto.NoResultsError, fn -> SonosHouseholds.get_players!(players.id) end
    end

    test "change_players/1 returns a players changeset" do
      players = players_fixture()
      assert %Ecto.Changeset{} = SonosHouseholds.change_players(players)
    end
  end

  describe "groups" do
    alias PR.SonosHouseholds.Group

    @valid_attrs %{group_id: "some group_id", name: "some name", player_ids: []}
    @update_attrs %{group_id: "some updated group_id", name: "some updated name", player_ids: []}
    @invalid_attrs %{group_id: nil, name: nil, player_ids: nil}

    def group_fixture(attrs \\ %{}) do
      {:ok, group} =
        attrs
        |> Enum.into(@valid_attrs)
        |> SonosHouseholds.create_group()

      group
    end

    test "list_groups/0 returns all groups" do
      group = group_fixture()
      assert SonosHouseholds.list_groups() == [group]
    end

    test "get_group!/1 returns the group with given id" do
      group = group_fixture()
      assert SonosHouseholds.get_group!(group.id) == group
    end

    test "create_group/1 with valid data creates a group" do
      assert {:ok, %Group{} = group} = SonosHouseholds.create_group(@valid_attrs)
      assert group.group_id == "some group_id"
      assert group.name == "some name"
      assert group.player_ids == []
    end

    test "create_group/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = SonosHouseholds.create_group(@invalid_attrs)
    end

    test "update_group/2 with valid data updates the group" do
      group = group_fixture()
      assert {:ok, %Group{} = group} = SonosHouseholds.update_group(group, @update_attrs)
      assert group.group_id == "some updated group_id"
      assert group.name == "some updated name"
      assert group.player_ids == []
    end

    test "update_group/2 with invalid data returns error changeset" do
      group = group_fixture()
      assert {:error, %Ecto.Changeset{}} = SonosHouseholds.update_group(group, @invalid_attrs)
      assert group == SonosHouseholds.get_group!(group.id)
    end

    test "delete_group/1 deletes the group" do
      group = group_fixture()
      assert {:ok, %Group{}} = SonosHouseholds.delete_group(group)
      assert_raise Ecto.NoResultsError, fn -> SonosHouseholds.get_group!(group.id) end
    end

    test "change_group/1 returns a group changeset" do
      group = group_fixture()
      assert %Ecto.Changeset{} = SonosHouseholds.change_group(group)
    end
  end
end
