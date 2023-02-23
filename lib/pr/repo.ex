defmodule PR.Repo do
  use Ecto.Repo,
    otp_app: :pr,
    adapter: Ecto.Adapters.Postgres,
    # See start/2 in applciation.ex
    log: false
end
