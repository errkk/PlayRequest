defmodule EWeb.Sonos.SonosAuthController do
  use EWeb, :controller

  alias E.SonosAPI

  def index(conn, _params) do
    login = SonosAPI.get_auth_link!()

    render(conn, "index.html", auth_link: login)
  end

  def authorized(conn, params) do
    SonosAPI.handle_auth_callback!(params)
    render(conn, "authorized.html")
  end

end
