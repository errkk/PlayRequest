defmodule PRWeb.PlaybackLive do
  require Logger
  use Phoenix.HTML
  use PRWeb, :live_view
  use PRWeb, :helpers

  alias PR.{Music, PlayState}
  alias PR.Music.{SonosItem, PlaybackState}
  alias PR.Auth
  alias PR.Auth.User
  alias PR.Scoring
  alias PR.Scoring.Point
  alias PR.Queue.Track
  alias PR.Queue

  import PRWeb.PlaybackComponents
  import PRWeb.TrackComponent
  import PRWeb.Shared

  embed_templates "*"

  @impl true
  def mount(_params, %{"user_id" => user_id}, socket) do
    if connected?(socket), do: PlayState.subscribe()
    if connected?(socket), do: Music.subscribe()
    play_state = PlayState.get(:play_state)
    metadata = PlayState.get(:metadata)
    progress = PlayState.get(:position)

    socket =
      assign(
        socket,
        metadata: metadata,
        play_state: play_state,
        progress: progress,
        result: [],
        q: nil,
        loading: nil,
        recently_liked: nil,
        participated: Queue.has_participated?(%User{id: user_id}),
        playlist: Music.get_playlist(%User{id: user_id}),
        page_title: page_title(metadata),
        show_encouraging_message: show_encouraging_message(%User{id: user_id}),
        can_super_like: can_super_like?(%User{id: user_id}),
        can_burn: can_burn?(%User{id: user_id})
      )
      |> assign(feature_flags())

    {:ok, assign_new(socket, :current_user, fn -> Auth.get_user!(user_id) end)}
  end

  defp show_encouraging_message(user) do
    Enum.all?([
      not Queue.has_participated?(user, :today),
      Queue.num_unplayed() == 0
    ])
  end

  defp can_super_like?(user) do
    user
    |> Scoring.count_likes_sent()
    |> Map.get(:super_likes)
    |> Kernel.<(super_likes_allowed())
  end

  defp can_burn?(user) do
    user
    |> Scoring.count_likes_sent()
    |> Map.get(:burns)
    |> Kernel.<(burns_allowed())
  end

  #
  # Subscription handlers
  #

  # Playback state update
  @impl true
  def handle_info({PlayState, %{} = play_state, :play_state}, socket) do
    {:noreply, assign(socket, play_state: play_state, page_title: page_title(play_state))}
  end

  # Progress update (interpolated from timer)
  def handle_info({PlayState, progress, :progress}, socket) do
    {:noreply, assign(socket, progress: progress)}
  end

  # Metadata webhook. Player is playing something else now
  def handle_info({PlayState, %{} = metadata, :metadata}, socket) do
    {:noreply,
     assign(socket,
       metadata: metadata,
       page_title: page_title(metadata),
       show_encouraging_message: false
     )}
  end

  # Clear errormode
  def handle_info({PlayState, nil, :sonos_error}, socket) do
    {:noreply, clear_flash(socket, :error)}
  end

  def handle_info({PlayState, %{error_code: error_code}, :sonos_error}, socket) do
    {:noreply, put_flash(socket, :error, "😵 Oh shit, an error from Sonos: \"#{error_code}\"")}
  end

  # Queue has changed either from addition or track has played
  def handle_info({Music, _num_unplayed, :queue_updated}, socket) do
    send(self(), {:get_playlist, nil})
    {:noreply, socket}
  end

  # Someone got a point. Was it me?
  def handle_info(
        {Music, %Point{reason: reason, track: %Track{name: name} = track}, :point},
        socket
      ) do
    send(self(), {:get_playlist, nil})

    if it_me?(track, socket) do
      socket =
        case reason do
          :super_like ->
            socket
            |> put_flash(:info, "🤩 You've got a superlike for \"#{name}\"!")
            |> assign(recently_liked: {track.id, reason})

          :like ->
            socket
            |> put_flash(:info, "🙌 You've received a unit of appreciation for \"#{name}\"")
            |> assign(recently_liked: {track.id, reason})

          :burn ->
            socket
            |> put_flash(:info, "🔥 You got fired for \"#{name}\"")
            |> assign(recently_liked: {track.id, reason})
        end

      {:noreply, socket}
    else
      {:noreply, socket}
    end
  end

  # Send flash message received from PubSub
  def handle_info(
        {Music, :flash, {level, message, user_id}},
        %{assigns: %{current_user: %User{id: requester_user_id}}} = socket
      )
      when requester_user_id == user_id do
    {:noreply, put_flash(socket, level, message)}
  end

  def handle_info({Music, :flash, {level, message, nil}}, socket) do
    {:noreply, put_flash(socket, level, message)}
  end

  def handle_info({Music, _, _}, socket) do
    {:noreply, socket}
  end

  #
  # Async UI functions
  #
  def handle_info({:search, ""}, socket) do
    # Empty serach query
    {:noreply, assign(socket, loading: false, result: [])}
  end

  def handle_info({:search, q}, socket) do
    case Music.search(q) do
      {:ok, tracks} ->
        {:noreply, assign(socket, loading: false, result: tracks)}

      _ ->
        {:noreply, assign(socket, loading: false, result: [])}
    end
  end

  def handle_info({:get_playlist, _}, %{assigns: %{current_user: user}} = socket) do
    items = Music.get_playlist(user)
    {:noreply, assign(socket, playlist: items)}
  end

  def handle_info({:queue, spotify_id}, %{assigns: %{current_user: user}} = socket) do
    case Music.queue(user, spotify_id) do
      {:ok, _track} ->
        socket =
          socket
          |> clear_flash(:error)
          |> assign(loading: false, result: [], q: nil)

        {:noreply, socket}

      #  Only pass error message for spotify_id field, as there are some other changeset
      # errors that we don't want to tell people about
      {:error, %{errors: [{:spotify_id, {message, _}} | _tail]}} ->
        Logger.warn("Double unplayed queue prevented: #{spotify_id}")

        socket =
          socket
          |> put_flash(:error, message)
          |> assign(loading: false)

        {:noreply, socket}

      err ->
        Logger.error("Track not queued for other reason: #{inspect(err)}")

        socket =
          socket
          |> put_flash(:error, "Something went wrong")
          |> assign(loading: false)

        {:noreply, socket}
    end
  end

  def handle_info(
        {:point, :like, track_id},
        %{assigns: %{current_user: %User{id: user_id}}} = socket
      ) do
    Scoring.create_point(%{track_id: track_id, user_id: user_id, reason: :like})
    send(self(), {:get_playlist, nil})
    #  Push event for addEventListener to pick up in JS
    {:noreply, push_event(socket, "point-given", %{reason: :like})}
  end

  def handle_info(
        {:point, reason, track_id},
        %{assigns: %{current_user: %User{id: user_id}}} = socket
      ) do
    Scoring.create_point(%{track_id: track_id, user_id: user_id, reason: reason})

    send(self(), {:get_playlist, nil})

    # Update this in case they've used their limit for the day
    socket =
      socket
      |> assign(can_super_like: can_super_like?(%User{id: user_id}))
      |> assign(can_burn: can_burn?(%User{id: user_id}))
      |> push_event("point-given", %{reason: reason})

    {:noreply, socket}
  end

  ## User events

  @impl true
  def handle_event("queue", %{"value" => spotify_id}, socket) do
    send(self(), {:queue, spotify_id})
    {:noreply, assign(socket, participated: true)}
  end

  def handle_event("search", %{"q" => q}, socket) when byte_size(q) <= 100 do
    send(self(), {:search, q})
    {:noreply, assign(socket, q: q, result: [], loading: true)}
  end

  def handle_event("like", %{"value" => track_id}, socket) do
    send(self(), {:point, :like, track_id})
    {:noreply, socket}
  end

  def handle_event("super_like", %{"value" => track_id}, socket) do
    send(self(), {:point, :super_like, track_id})

    {:noreply, socket}
  end

  def handle_event("burn", %{"value" => track_id}, socket) do
    send(self(), {:point, :burn, track_id})

    {:noreply, socket}
  end

  # This is all happening cos the @page_title is a single var and cant match playback_state and metadata in the template
  defp page_title(%PlaybackState{state: :paused}), do: "⏸️"
  defp page_title(%PlaybackState{state: :idle}), do: "..."

  defp page_title(%PlaybackState{state: :playing}),
    do: :metadata |> PlayState.get() |> page_title()

  defp page_title(%{current_item: %SonosItem{name: name, artist: artist}}) do
    case PlayState.get(:play_state) do
      %PlaybackState{state: :playing} ->
        "🎵 #{name} – #{artist}"

      _ ->
        "..."
    end
  end

  defp page_title(_), do: "..."

  defp super_likes_allowed() do
    :pr
    |> Application.get_env(:super_likes_allowed)
    |> String.to_integer()
  end

  defp burns_allowed() do
    :pr
    |> Application.get_env(:burns_allowed)
    |> String.to_integer()
  end
end
