defmodule PRWeb.WrappedControllerTest do
  use PRWeb.ConnCase

  setup do
    flags = Application.get_env(:pr, :feature_flags)
    on_exit(fn -> Application.put_env(:pr, :feature_flags, flags) end)
    %{flags: flags}
  end

  defp get_wrapped(conn, user) do
    conn
    |> init_test_session(user_id: user.id)
    |> get(~p"/wrapped")
  end

  test "redirects when the flag is off and user isn't trusted", %{conn: conn} do
    assert redirected_to(get_wrapped(conn, insert(:user))) == ~p"/"
  end

  test "trusted users see it with the flag off", %{conn: conn} do
    assert html_response(get_wrapped(conn, insert(:user, is_trusted: true)), 200) =~ "Wrapped"
  end

  test "everyone sees it with the flag on, spicy cards stay hidden", %{conn: conn, flags: flags} do
    Application.put_env(:pr, :feature_flags, Keyword.put(flags, :show_wrapped, "true"))
    html = html_response(get_wrapped(conn, insert(:user)), 200)

    assert html =~ "Top DJs"
    refute html =~ "Unrequited"
  end
end
