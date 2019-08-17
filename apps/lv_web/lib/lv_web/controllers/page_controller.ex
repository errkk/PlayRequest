defmodule EWeb.PageController do
  use EWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end

end

