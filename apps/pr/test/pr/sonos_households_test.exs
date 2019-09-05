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
end
