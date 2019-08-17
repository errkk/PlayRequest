defmodule EWeb.Router do
  use EWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_flash
    plug Phoenix.LiveView.Flash
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", EWeb do
    pipe_through :browser

    get "/", Sonos.SonosAuthController, :index
    get "/authorized", Sonos.SonosAuthController, :authorized
    get "/token-callback", Sonos.SonosAuthController, :token_callback

    live "/clock", ClockLive
  end

  scope "/sonos", EWeb.Sonos do
    pipe_through :api
    get "/callback", SonosWebhookController, :callback
  end

  # Other scopes may use custom stacks.
  # scope "/api", EWeb do
  #   pipe_through :api
  # end
end
