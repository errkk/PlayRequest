defmodule PRWeb.Plug.ReleaseMetadataPlug do
  @moduledoc false
  @behaviour Plug

  use PRWeb, :plug

  def init(opts), do: opts

  def call(conn, _) do
    merge_assigns(conn, get_release_metadata())
  end

  defp get_release_metadata do
    [
      version: System.get_env("HEROKU_RELEASE_VERSION", "dev"),
      commit: System.get_env("HEROKU_SLUG_COMMIT", "dev")
    ]
  end
end
