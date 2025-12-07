defmodule PRWeb.AuthHooks do
  @moduledoc """
  LiveView authentication hooks for handling user sessions.
  """
  use PRWeb, :verified_routes

  import Phoenix.Component
  import Phoenix.LiveView

  alias PR.Auth

  def on_mount(:require_authenticated_user, _params, %{"user_id" => user_id} = session, socket) do
    require Logger
    Logger.debug("AuthHook: Found user_id in session: #{inspect(user_id)}")
    Logger.debug("AuthHook: Full session: #{inspect(session)}")

    case Auth.get_user(user_id) do
      nil ->
        Logger.debug("AuthHook: User not found in database for user_id: #{inspect(user_id)}")

        socket =
          socket
          |> put_flash(:error, "You must log in to access this page.")
          |> redirect(to: ~p"/auth")

        {:halt, socket}

      user ->
        Logger.debug("AuthHook: User authenticated: #{inspect(user.id)}")
        {:cont, assign(socket, current_user: user)}
    end
  end

  def on_mount(:require_authenticated_user, _params, session, socket) do
    require Logger
    Logger.debug("AuthHook: No user_id in session. Session: #{inspect(session)}")

    socket =
      socket
      |> put_flash(:error, "You must log in to access this page.")
      |> redirect(to: ~p"/auth")

    {:halt, socket}
  end
end
