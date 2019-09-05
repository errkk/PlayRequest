defmodule PR.Repo do
  use Ecto.Repo,
    otp_app: :pr,
    adapter: Ecto.Adapters.Postgres
end
