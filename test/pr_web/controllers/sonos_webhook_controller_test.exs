defmodule PRWeb.SonosWebhookControllerTest do
  use PRWeb.ConnCase, async: true
  import ExUnit.CaptureLog

  alias PRWeb.Fixtures.Sonos.CurrentAndNext
  alias PRWeb.Fixtures.Sonos.Error

  alias PR.Repo
  alias PR.Queue
  alias PR.Queue.Track

  describe "headers" do
    test "Check group id from header", %{conn: conn} do
      insert(:track, spotify_id: "0XhXnY0lBzbdEWktDHknsl")
      insert(:group, group_id: "RINCON:GROUPID", is_active: true)

      capture_log(fn ->
        conn =
          conn
          |> put_req_header("content-type", "application/json")
          |> put_req_header("x-sonos-target-value", "RINCON:GROUPID")
          |> post(~p"/sonos/callback", CurrentAndNext.json())

        assert response(conn, 202)
      end)
    end
  end

  describe "metadata" do
    test "set current track when there is a next", %{conn: conn} do
      insert(:track, spotify_id: "0XhXnY0lBzbdEWktDHknsl")
      insert(:group, group_id: "RINCON:GROUPID", is_active: true)

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("x-sonos-target-value", "RINCON:GROUPID")
        |> post(~p"/sonos/callback", CurrentAndNext.json())

      assert response(conn, 202)
      assert %{spotify_id: "0XhXnY0lBzbdEWktDHknsl"} = Queue.get_playing()
    end

    test "dont handle if group id is different", %{conn: conn} do
      insert(:track, playing_since: nil, spotify_id: "0XhXnY0lBzbdEWktDHknsl")

      assert capture_log(fn ->
               conn =
                 conn
                 |> put_req_header("content-type", "application/json")
                 |> put_req_header("x-sonos-target-value", "RINCON:WHODIS???")
                 |> post(~p"/sonos/callback", CurrentAndNext.json())

               assert response(conn, 202)
               assert is_nil(Queue.get_playing())
             end) =~ "Skipping"
    end

    test "set current track when current is already playing", %{conn: conn} do
      insert(:track, playing_since: DateTime.utc_now(), spotify_id: "0XhXnY0lBzbdEWktDHknsl")
      insert(:group, group_id: "RINCON:GROUPID", is_active: true)

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("x-sonos-target-value", "RINCON:GROUPID")
        |> post(~p"/sonos/callback", CurrentAndNext.json())

      assert response(conn, 202)
      assert %{spotify_id: "0XhXnY0lBzbdEWktDHknsl"} = Queue.get_playing()
    end

    test "old track set played", %{conn: conn} do
      insert(:group, group_id: "RINCON:GROUPID", is_active: true)
      old = insert(:playing_track, spotify_id: "something else")

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("x-sonos-target-value", "RINCON:GROUPID")
        |> post(~p"/sonos/callback", CurrentAndNext.json())

      assert response(conn, 202)
      refute Queue.get_playing()
      assert %{played_at: %DateTime{}} = Repo.get(Track, old.id)
    end

    test "old track set played update current", %{conn: conn} do
      insert(:group, group_id: "RINCON:GROUPID", is_active: true)
      old = insert(:playing_track, spotify_id: "something else")
      new = insert(:track, spotify_id: "0XhXnY0lBzbdEWktDHknsl")

      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("x-sonos-target-value", "RINCON:GROUPID")
        |> post(~p"/sonos/callback", CurrentAndNext.json())

      assert response(conn, 202)
      assert %{spotify_id: "0XhXnY0lBzbdEWktDHknsl"} = Queue.get_playing()
      assert %{played_at: %DateTime{}} = Repo.get(Track, old.id)
    end
  end

  describe "error webhook" do
    test "error code", %{conn: conn} do
      conn =
        conn
        |> put_req_header("content-type", "application/json")
        |> put_req_header("x-sonos-target-value", "RINCON:GROUPID")
        |> post(~p"/sonos/callback", Error.lost_connection())

      assert response(conn, 202)
    end
  end
end
