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

  scope "/sonos", EWeb.Sonos do
    pipe_through :browser
    get "/connect", SonosAuthController, :index
    get "/authorized", SonosAuthController, :authorized
  end

  scope "/sonos", EWeb.Sonos do
    pipe_through :api
    post "/callback", SonosWebhookController, :callback
  end

  scope "/sonos/cloud-queue", EWeb.Sonos do
    pipe_through :api
    get "/context", SonosCloudQueueController, :context
    get "/itemWindow", SonosCloudQueueController, :item_window
    get "/version", SonosCloudQueueController, :version
    post "/timePlayed", SonosCloudQueueController, :time_played
  end

end
