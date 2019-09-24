defmodule PRWeb.Plug.NowPlayingPlug do
  @moduledoc false
  @behaviour Plug

  use PRWeb, :plug
  alias PR.Queue
  alias PR.Queue.Track

  def init(opts), do: opts

  def call(conn, _) do
    merge_assigns(conn, get_now_playing())
  end

  defp get_now_playing do
    case Queue.get_playing() do
      %Track{} = track ->
        IO.inspect track
        [ now_playing: track ]
      _ ->
        nil
      end
  end
end
