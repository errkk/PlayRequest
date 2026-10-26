defmodule PRWeb.WrappedController do
  use PRWeb, :controller

  import PRWeb.Shared, only: [feature_flags: 0]

  alias PR.Auth.User
  alias PR.Wrapped

  def index(%{assigns: %{current_user: %User{} = user}} = conn, _params) do
    flags = feature_flags()

    if flags.show_wrapped or user.is_trusted do
      render(conn, :index,
        page_title: "Wrapped",
        wrapped: Wrapped.all(Date.utc_today().year, user.id),
        spicy: flags.show_wrapped_spicy or user.is_trusted == true
      )
    else
      redirect(conn, to: ~p"/")
    end
  end
end
