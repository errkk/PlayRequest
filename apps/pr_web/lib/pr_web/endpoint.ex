defmodule PRWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :pr_web

  @session_options [
    store: :cookie,
    key: "_pr_web_key",
    signing_salt: "ZG+jiBR2"
  ]

  # Can replace this with Phoenix.LiveView.Socket when phx is 1.5
  socket "/live", PR.LiveView.Socket,
    websocket: [timeout: 45_000, connect_info: [session: @session_options], log: false],
    longpoll: false

  socket "/socket", PRWeb.UserSocket,
    websocket: [timeout: 45_000, connect_info: [session: @session_options], log: false],
    longpoll: false

  # Serve at "/" the static files from "priv/static" directory.
  #
  # You should set gzip to true if you are running phx.digest
  # when deploying your static files in production.
  plug Plug.Static,
    at: "/",
    from: :pr_web,
    gzip: false,
    only: ~w(css fonts images js favicon.ico robots.txt)

  # Code reloading can be explicitly enabled under the
  # :code_reloader configuration of your endpoint.
  if code_reloading? do
    socket "/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket
    plug Phoenix.LiveReloader
    plug Phoenix.CodeReloader
  end

  plug Plug.RequestId
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  plug Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Phoenix.json_library()

  plug Plug.MethodOverride
  plug Plug.Head

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  plug Plug.Session, @session_options

  plug PRWeb.Router
end
