defmodule PRWeb.Router do
  use PRWeb, :router

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

  scope "/", PRWeb do
    pipe_through :browser
    get "/page", PageController, :index
    live "/", PlaybackLive
  end

  scope "/", PRWeb.Service do
    pipe_through :browser

    scope "/setup" do
      get "/", ServiceSetupController, :index
      post "/save-households", ServiceSetupController, :save_households
      post "/save-groups", ServiceSetupController, :save_groups
      put "/household/:id", ServiceSetupController, :toggle_household
      put "/group/:id", ServiceSetupController, :toggle_group
      post "/subscribe", ServiceSetupController, :subscribe_sonos_webhooks
      post "/sync-playlist", ServiceSetupController, :sync_playlist
      post "/load-playlist", ServiceSetupController, :load_playlist
    end

    get "/sonos/authorized", ServiceAuthController, :authorized_sonos, as: :sonos_auth
    get "/spotify/authorized", ServiceAuthController, :authorized_spotify, as: :spotify_auth
  end

  scope "/sonos", PRWeb.Service do
    pipe_through :api
    post "/callback", SonosWebhookController, :callback
  end

end
