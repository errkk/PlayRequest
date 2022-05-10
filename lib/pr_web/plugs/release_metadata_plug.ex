defmodule PRWeb.Plug.ReleaseMetadataPlug do
  @moduledoc false

  use PRWeb, :plug

  def init(opts), do: opts

  def call(conn, _) do
    merge_assigns(conn, get_release_metadata())
  end

  defp get_release_metadata do
    [
      version: System.get_env("APP_REVISION", "dev"),
    ]
  end
end
