defmodule E.Repo do
  use Ecto.Repo,
    otp_app: :lv,
    adapter: Ecto.Adapters.Postgres
end
