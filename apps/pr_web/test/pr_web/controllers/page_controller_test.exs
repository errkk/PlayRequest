defmodule PRWeb.PageControllerTest do
  use PRWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, "/")
    assert redirected_to(conn) == Routes.auth_path(conn, :google, :request)
  end
end
