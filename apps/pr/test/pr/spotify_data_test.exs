defmodule PR.SpotifyDataTest do
  use PR.DataCase

  alias PR.SpotifyData

  describe "spotify_playlists" do
    alias PR.SpotifyData.Playlist

    @valid_attrs %{playlist_id: "some playlist_id"}
    @update_attrs %{playlist_id: "some updated playlist_id"}
    @invalid_attrs %{playlist_id: nil}

    def playlist_fixture(attrs \\ %{}) do
      {:ok, playlist} =
        attrs
        |> Enum.into(@valid_attrs)
        |> SpotifyData.create_playlist()

      playlist
    end

    test "list_spotify_playlists/0 returns all spotify_playlists" do
      playlist = playlist_fixture()
      assert SpotifyData.list_spotify_playlists() == [playlist]
    end

    test "get_playlist!/1 returns the playlist with given id" do
      playlist = playlist_fixture()
      assert SpotifyData.get_playlist!(playlist.id) == playlist
    end

    test "create_playlist/1 with valid data creates a playlist" do
      assert {:ok, %Playlist{} = playlist} = SpotifyData.create_playlist(@valid_attrs)
      assert playlist.playlist_id == "some playlist_id"
    end

    test "create_playlist/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = SpotifyData.create_playlist(@invalid_attrs)
    end

    test "update_playlist/2 with valid data updates the playlist" do
      playlist = playlist_fixture()
      assert {:ok, %Playlist{} = playlist} = SpotifyData.update_playlist(playlist, @update_attrs)
      assert playlist.playlist_id == "some updated playlist_id"
    end

    test "update_playlist/2 with invalid data returns error changeset" do
      playlist = playlist_fixture()
      assert {:error, %Ecto.Changeset{}} = SpotifyData.update_playlist(playlist, @invalid_attrs)
      assert playlist == SpotifyData.get_playlist!(playlist.id)
    end

    test "delete_playlist/1 deletes the playlist" do
      playlist = playlist_fixture()
      assert {:ok, %Playlist{}} = SpotifyData.delete_playlist(playlist)
      assert_raise Ecto.NoResultsError, fn -> SpotifyData.get_playlist!(playlist.id) end
    end

    test "change_playlist/1 returns a playlist changeset" do
      playlist = playlist_fixture()
      assert %Ecto.Changeset{} = SpotifyData.change_playlist(playlist)
    end
  end

  describe "spotify_users" do
    alias PR.SpotifyData.SpotifyUser

    @valid_attrs %{display_name: "some display_name", user_id: "some user_id"}
    @update_attrs %{display_name: "some updated display_name", user_id: "some updated user_id"}
    @invalid_attrs %{display_name: nil, user_id: nil}

    def spotify_user_fixture(attrs \\ %{}) do
      {:ok, spotify_user} =
        attrs
        |> Enum.into(@valid_attrs)
        |> SpotifyData.create_spotify_user()

      spotify_user
    end

    test "list_spotify_users/0 returns all spotify_users" do
      spotify_user = spotify_user_fixture()
      assert SpotifyData.list_spotify_users() == [spotify_user]
    end

    test "get_spotify_user!/1 returns the spotify_user with given id" do
      spotify_user = spotify_user_fixture()
      assert SpotifyData.get_spotify_user!(spotify_user.id) == spotify_user
    end

    test "create_spotify_user/1 with valid data creates a spotify_user" do
      assert {:ok, %SpotifyUser{} = spotify_user} = SpotifyData.create_spotify_user(@valid_attrs)
      assert spotify_user.display_name == "some display_name"
      assert spotify_user.user_id == "some user_id"
    end

    test "create_spotify_user/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = SpotifyData.create_spotify_user(@invalid_attrs)
    end

    test "update_spotify_user/2 with valid data updates the spotify_user" do
      spotify_user = spotify_user_fixture()
      assert {:ok, %SpotifyUser{} = spotify_user} = SpotifyData.update_spotify_user(spotify_user, @update_attrs)
      assert spotify_user.display_name == "some updated display_name"
      assert spotify_user.user_id == "some updated user_id"
    end

    test "update_spotify_user/2 with invalid data returns error changeset" do
      spotify_user = spotify_user_fixture()
      assert {:error, %Ecto.Changeset{}} = SpotifyData.update_spotify_user(spotify_user, @invalid_attrs)
      assert spotify_user == SpotifyData.get_spotify_user!(spotify_user.id)
    end

    test "delete_spotify_user/1 deletes the spotify_user" do
      spotify_user = spotify_user_fixture()
      assert {:ok, %SpotifyUser{}} = SpotifyData.delete_spotify_user(spotify_user)
      assert_raise Ecto.NoResultsError, fn -> SpotifyData.get_spotify_user!(spotify_user.id) end
    end

    test "change_spotify_user/1 returns a spotify_user changeset" do
      spotify_user = spotify_user_fixture()
      assert %Ecto.Changeset{} = SpotifyData.change_spotify_user(spotify_user)
    end
  end
end
