defmodule PRWeb.Shared do
  alias PR.Auth.User

  def installation_name do
    Application.get_env(:pr, :installation_name, "PlayRequest")
  end

  def name(%User{first_name: first_name, last_name: last_name}) do
    first_name <> " " <> String.first(last_name)
  end

  def feature_flags() do
    Application.get_env(:pr, :feature_flags)
    |> Map.new(fn {k, v} -> {k, v == "true"} end)
  end
end
