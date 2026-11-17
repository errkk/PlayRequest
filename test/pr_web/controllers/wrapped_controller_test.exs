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

  test "redirects when the flag is off", %{conn: conn} do
    assert redirected_to(get_wrapped(conn, insert(:user))) == ~p"/"
  end

  test "redirects trusted users when the flag is off", %{conn: conn} do
    assert redirected_to(get_wrapped(conn, insert(:user, is_trusted: true))) == ~p"/"
  end

  test "everyone sees it with the flag on, spicy cards stay hidden", %{conn: conn, flags: flags} do
    Application.put_env(:pr, :feature_flags, Keyword.put(flags, :show_wrapped, "true"))
    html = html_response(get_wrapped(conn, insert(:user)), 200)

    assert html =~ "Top DJs"
    refute html =~ "Unrequited"
  end

  test "users with the flag see it with the env flag off", %{conn: conn} do
    insert(:point)
    html = html_response(get_wrapped(conn, insert(:user, feature_flags: ["show_wrapped"])), 200)

    assert html =~ "Top DJs"
    refute html =~ "Unrequited"
  end

  test "users with the spicy flag see spicy cards", %{conn: conn} do
    insert(:point)
    user = insert(:user, feature_flags: ["show_wrapped", "show_wrapped_spicy"])

    assert html_response(get_wrapped(conn, user), 200) =~ "Unrequited"
  end

  test "trusted users don't see spicy cards without the flag", %{conn: conn} do
    insert(:point)

    user = insert(:user, is_trusted: true, feature_flags: ["show_wrapped"])

    refute html_response(get_wrapped(conn, user), 200) =~ "Unrequited"
  end
end
