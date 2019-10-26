defmodule Mix.Tasks.Proxy do
  use Mix.Task

  @shortdoc "Runs the proxy for development"

  def run(_) do
    System.cmd("ssh", ["-R", subdomain() <> ":80:localhost:4000", "serveo.net"])
  end

  defp subdomain do
    System.get_env("DEV_PROXY_SUBDOMAIN")
  end
end
