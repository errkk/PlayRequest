defmodule PRWeb.SonosWebhookControllerTest do
  use PRWeb.ConnCase

  alias PRWeb.Fixtures.Sonos.CurrentAndNext

  alias PR.Repo
  alias PR.Queue
  alias PR.Queue.Track

  describe "metadata" do
    test "set current track when there is a next", %{conn: conn} do
      insert(:track, playing_since: nil, spotify_id: "0XhXnY0lBzbdEWktDHknsl")
      conn = conn
      |> put_req_header("content-type", "application/json")
      |> post(Routes.sonos_webhook_path(conn, :callback), CurrentAndNext.json())
      assert json_response(conn, 200)
      assert %{spotify_id: "0XhXnY0lBzbdEWktDHknsl"} = Queue.get_playing()
    end

    test "set current track when current is already playing", %{conn: conn} do
      insert(:track, playing_since: DateTime.utc_now(), spotify_id: "0XhXnY0lBzbdEWktDHknsl")
      conn = conn
      |> put_req_header("content-type", "application/json")
      |> post(Routes.sonos_webhook_path(conn, :callback), CurrentAndNext.json())
      assert json_response(conn, 200)
      assert %{spotify_id: "0XhXnY0lBzbdEWktDHknsl"} = Queue.get_playing()
    end

    test "old track set played", %{conn: conn} do
      old = insert(:track, playing_since: DateTime.utc_now(), spotify_id: "something else")

      conn = conn
      |> put_req_header("content-type", "application/json")
      |> post(Routes.sonos_webhook_path(conn, :callback), CurrentAndNext.json())
      assert json_response(conn, 200)
      refute Queue.get_playing()
      assert %{played_at: %DateTime{}} = Repo.get(Track, old.id)
    end

    test "old track set played update current", %{conn: conn} do
      old = insert(:track, playing_since: DateTime.utc_now(), spotify_id: "something else")
      new = insert(:track, playing_since: nil, spotify_id: "0XhXnY0lBzbdEWktDHknsl")

      conn = conn
      |> put_req_header("content-type", "application/json")
      |> post(Routes.sonos_webhook_path(conn, :callback), CurrentAndNext.json())
      assert json_response(conn, 200)
      assert %{spotify_id: "0XhXnY0lBzbdEWktDHknsl"} = Queue.get_playing()
      assert %{played_at: %DateTime{}} = Repo.get(Track, old.id)
    end
  end
end

