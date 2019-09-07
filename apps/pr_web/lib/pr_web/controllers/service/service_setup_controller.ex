defmodule PRWeb.Service.ServiceSetupController do
  use PRWeb, :controller

  alias PR.SonosAPI
  alias PR.SpotifyAPI
  alias PR.SonosHouseholds

  def index(conn, _params) do
    households = SonosHouseholds.list_houeholds()
    groups = SonosHouseholds.list_groups()
    render(
      conn,
      "index.html",
      households: households,
      groups: groups)
  end
end

