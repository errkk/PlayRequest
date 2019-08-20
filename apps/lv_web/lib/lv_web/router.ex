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
    get "/page", PageController, :index
    live "/", PlaybackLive
  end

  scope "/", EWeb.Service do
    pipe_through :browser
    get "/connect", ServiceAuthController, :index
    get "/sonos/authorized", ServiceAuthController, :authorized_sonos, as: :sonos_auth
    get "/spotify/authorized", ServiceAuthController, :authorized_spotify, as: :spotify_auth
  end

  scope "/sonos", EWeb.Service do
    pipe_through :api
    post "/callback", SonosWebhookController, :callback
  end

end
