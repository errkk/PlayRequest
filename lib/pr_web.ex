defmodule PRWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use PRWeb, :controller
      use PRWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def static_paths, do: ~w(assets fonts images favicon.ico robots.txt)

  def controller do
    quote do
      use Phoenix.Controller, namespace: PRWeb
      # formats: [:html, :json],
      # layouts: [html: PRWeb.Layouts]
      import Plug.Conn
      import PRWeb.Gettext
      alias PRWeb.Router.Helpers, as: Routes
      import Phoenix.LiveView.Controller

      unquote(verified_routes())
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/pr_web/templates",
        namespace: PRWeb

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_flash: 1, get_flash: 2, view_module: 1]
      import Phoenix.Component

      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      import PRWeb.ErrorHelpers
      import PRWeb.Gettext
      import PRWeb.SharedView
      alias PRWeb.Router.Helpers, as: Routes
      unquote(html_helpers())
      unquote(verified_routes())
    end
  end

  def router do
    quote do
      use Phoenix.Router
      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
      import Phoenix.LiveDashboard.Router
    end
  end

  def plug do
    quote do
      import Plug.Conn
      use Phoenix.Controller, namespace: PRWeb
      alias PRWeb.Router.Helpers, as: Routes
      unquote(verified_routes())
    end
  end

  def channel do
    quote do
      use Phoenix.Channel, log_join: :debug, log_handle_in: false
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {PRWeb.Layouts, :app}

      unquote(html_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(verified_routes())
      unquote(html_helpers())
    end
  end

  def html do
    quote do
      use Phoenix.Component

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [get_csrf_token: 0, view_module: 1, view_template: 1]

      # Include general helpers for rendering HTML
      unquote(html_helpers())
      unquote(verified_routes())
    end
  end

  defp html_helpers do
    quote do
      # HTML escaping functionality
      import Phoenix.HTML
      # Core UI components and translation
      import PRWeb.CoreComponents
      import PRWeb.Gettext

      # Shortcut for generating JS commands
      alias Phoenix.LiveView.JS

      # installation_name() etc
      import PRWeb.Shared

      # Routes generation with the ~p sigil
      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: PRWeb.Endpoint,
        router: PRWeb.Router,
        statics: PRWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
