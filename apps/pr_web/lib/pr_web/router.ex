defmodule PRWeb.Router do
  use PRWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_live_flash
    plug :put_root_layout, {PRWeb.LayoutView, :root}
    plug PRWeb.Plug.ReleaseMetadataPlug
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  pipeline :auth do
    plug PRWeb.Plug.AuthPlug
  end

  pipeline :trusted do
    plug PRWeb.Plug.TrustedPlug
  end

  pipeline :now_playing do
    plug PRWeb.Plug.NowPlayingPlug
  end

  scope "/stats" do
    pipe_through [:browser, :auth, :trusted]
    live_dashboard "/dashboard", metrics: PR.Telemetry
  end

  scope "/", PRWeb do
    pipe_through [:browser, :auth, :now_playing]
    live "/", PlaybackLive
    get "/history", HistoryController, :index
    post "/history/track-unplayed/:id", HistoryController, :mark_unplayed
  end

  scope "/auth", PRWeb do
    pipe_through [:browser, :now_playing]
    get "/", AuthController, :index
    get "/delete", AuthController, :delete
    get "/:provider", AuthController, :request
    get "/:provider/callback", AuthController, :callback
  end

  scope "/", PRWeb.Service do
    pipe_through [:browser, :auth]

    scope "/setup" do
      get "/", ServiceSetupController, :index
      post "/save-households", ServiceSetupController, :save_households
      post "/save-groups", ServiceSetupController, :save_groups
      delete "/clear-groups", ServiceSetupController, :clear_groups
      put "/household/:id", ServiceSetupController, :toggle_household
      put "/group/:id", ServiceSetupController, :toggle_group
      post "/subscribe", ServiceSetupController, :subscribe_sonos_webhooks
      post "/sync-playlist", ServiceSetupController, :sync_playlist
      post "/load-playlist", ServiceSetupController, :load_playlist
      post "/create-playlist", ServiceSetupController, :create_spotify_playlist
      post "/bump", ServiceSetupController, :bump
    end

    get "/sonos/authorized", ServiceAuthController, :authorized_sonos, as: :sonos_auth
    get "/spotify/authorized", ServiceAuthController, :authorized_spotify, as: :spotify_auth
  end

  scope "/sonos", PRWeb.Service do
    pipe_through :api
    post "/callback", SonosWebhookController, :callback
  end

end
