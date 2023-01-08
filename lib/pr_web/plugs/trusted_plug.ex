defmodule PRWeb.Plug.TrustedPlug do
  @moduledoc false

  use PRWeb, :plug
  alias PR.Auth.User

  def init(opts), do: opts

  def call(%{assigns: %{current_user: %User{is_trusted: true}}} = conn, _) do
    conn
  end

  def call(conn, _) do
    nope(conn)
  end

  defp nope(conn) do
    conn
    |> redirect(to: ~p"/auth")
    |> halt()
  end
end
