defmodule PRWeb.Presence do
  use Phoenix.Presence,
    otp_app: :pr,
    pubsub_server: PR.PubSub

  alias PR.Auth

  def fetch(_topic, presences) do
    users = presences |> Map.keys() |> Auth.get_users_map()

    for {key, %{metas: metas}} <- presences, into: %{} do
      {key, %{metas: metas, user: users[String.to_integer(key)]}}
    end
  end
end
