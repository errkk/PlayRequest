defmodule PRWeb.UserHeaderLive do
  require Logger
  use Phoenix.LiveView
  use Phoenix.HTML

  alias PR.Auth
  alias PR.Auth.User
  alias PR.Music
  alias PR.Scoring
  alias PR.Queue.Track
  alias PRWeb.PlaybackView
  alias PRWeb.UserHeaderView

  def render(assigns) do
    UserHeaderView.render("index.html", assigns)
  end

  def mount(%{user_id: user_id}, socket) when not is_nil(user_id) do
    if connected?(socket), do: Music.subscribe()

    socket = assign(
      socket,
      points: Scoring.count_points(%User{id: user_id})
    )

    {:ok, assign_new(socket, :current_user, fn -> Auth.get_user!(user_id) end)}
  end


  def mount(_, socket) do
    socket = assign(
      socket,
      points: 0
    )

    {:ok, socket}
  end

  #
  # Subscription handlers
  #

  def handle_info({Music, %Track{} = track, :point}, %{assigns: %{current_user: %User{id: user_id}}} = socket) do
    if PlaybackView.it_me?(track, socket) do
      {:noreply, assign(
        socket,
        points: Scoring.count_points(%User{id: user_id})
        )}
    else
      {:noreply, socket}
    end
  end

  def handle_info(_, socket) do
    {:noreply, socket}
  end

end

