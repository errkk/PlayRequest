defmodule PRWeb.Router do
  use PRWeb, :router

  pipeline :browser do
    plug(:accepts, ["html"])
    plug(:fetch_session)
    plug(:protect_from_forgery)
    plug(:put_secure_browser_headers)
    plug(:fetch_live_flash)
    plug(:put_root_layout, {PRWeb.Layouts, :root})
    plug(PRWeb.Plug.ReleaseMetadataPlug)
  end

  pipeline :api do
    plug(:accepts, ["json"])
  end

  pipeline :auth do
    plug(PRWeb.Plug.AuthPlug)
    plug(PRWeb.Plug.UserSocketToken)
  end

  pipeline :trusted do
    plug(PRWeb.Plug.TrustedPlug)
  end

  pipeline :now_playing do
    plug(PRWeb.Plug.NowPlayingPlug)
  end

  scope "/", PRWeb do
    #  Not using auth pipeline here cos AuthHooks is doing the same thing
    # for live views. apparently
    pipe_through([:browser, :now_playing])

    live_session :authenticated,
      on_mount: [{PRWeb.AuthHooks, :require_authenticated_user}] do
      live("/", PlaybackLive)
    end
  end

  scope "/history", PRWeb do
    # Authenticated routes for history, using controlers so AuthPlug
    pipe_through([:browser, :auth])

    get("/", HistoryController, :index)
    post("/track-unplayed/:id", HistoryController, :mark_unplayed)
  end

  scope "/auth", PRWeb do
    pipe_through([:browser, :now_playing])
    get("/", AuthController, :index)
    get("/delete", AuthController, :delete)
    get("/:provider", AuthController, :request)
    get("/:provider/callback", AuthController, :callback)
  end

  scope "/setup", PRWeb.Service do
    # Authenticated controller routes for doing setup stuff
    pipe_through([:browser, :auth])

    get("/", ServiceSetupController, :index)
    post("/save-households", ServiceSetupController, :save_households)
    post("/save-groups", ServiceSetupController, :save_groups)
    delete("/clear-groups", ServiceSetupController, :clear_groups)
    put("/household/:id", ServiceSetupController, :toggle_household)
    put("/group/:id", ServiceSetupController, :toggle_group)
    post("/subscribe", ServiceSetupController, :subscribe_sonos_webhooks)
    post("/sync-playlist", ServiceSetupController, :sync_playlist)
    post("/trigger-playlist", ServiceSetupController, :trigger_playlist)
    post("/create-playlist", ServiceSetupController, :create_spotify_playlist)
    post("/bump", ServiceSetupController, :bump)
    post("/get-state", ServiceSetupController, :get_state)
  end

  scope "/", PRWeb.Service do
    # Plublic controller routes for authenticating services
    pipe_through([:browser])
    get("/sonos/authorized", ServiceAuthController, :authorized_sonos, as: :sonos_auth)
    get("/spotify/authorized", ServiceAuthController, :authorized_spotify, as: :spotify_auth)
  end

  scope "/sonos", PRWeb.Service do
    pipe_through(:api)
    post("/callback", SonosWebhookController, :callback)
  end
end
