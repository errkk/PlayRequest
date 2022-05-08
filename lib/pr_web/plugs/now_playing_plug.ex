defmodule PRWeb.Plug.NowPlayingPlug do
  @moduledoc false

  use PRWeb, :plug
  alias PR.Queue
  alias PR.Queue.Track

  def init(opts), do: opts

  def call(conn, _) do
    case Queue.get_playing() do
      %Track{} = track ->
        merge_assigns(conn, now_playing: track)
      _ ->
        conn
    end
  end
end
