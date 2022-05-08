defmodule PRWeb.PageController do
  use PRWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

end

