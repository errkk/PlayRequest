defmodule PRWeb.TrackComponent do
  use PRWeb, :html

  alias PR.Queue.Track
  alias PR.Music.PlaybackState

  def track(assigns) do
    ~H"""
      <div class={"track #{wobble?(@recently_liked, @track)}#{if is_playing?(@track, @play_state), do: "playing"} #{if dun_voted?(@track), do: "has-voted"}"}>
        <div class="track__inner">

            <div class="track__img__container">
              <%= if can_vote?(@track, @current_user) do %>
                <button
                  class="flip__container animate"
                  phx-click="like"
                  value={@track.id}
                  title={"Give some appreciation to #{name @track.user}"}
                >
                  <div class="flip__flipper">
                    <img src={@track.img} width="100" class="track__img flip__front" />
                    <span class="flip__back"></span>
                  </div>
                </button>
              <% else %>
                <img src={@track.img} width="100" class="track__img" />
              <% end %>
            </div>

            <div class="track__details">
              <h3 class="track__name">
                <%= if is_playing?(@track, @play_state) do %>
                  <img src={~p"/images/playing-icon.svg"} class="track__playing" />
                <% end %>
                <%= @track.name %>
                <%= if @track.track_novelty < 20 do %>
                  <span title={"Track novelty: #{@track.track_novelty}"}>😴</span>
                <% end %>
              </h3>
              <p class="track__artist">
                <%= @track.artist %>
                <%= if @track.artist_novelty < 20 do %>
                  <span title={"Artist novelty: #{@track.artist_novelty}"}>😴</span>
                <% end %>
              </p>

              <div class="chips">
                <.chip text={name @track.user} img={@track.user.image} />
                <.heart points={@track.points_received} />
              </div>
            </div>

          <.novelty track={@track} />

        </div>
        <.progress track={@track} play_state={@play_state} progress={@progress} />
      </div>
    """
  end
  
  def chip(assigns) do
    ~H"""
      <div class="chip">
        <img src={@img} width="40" class="chip__img" />
        <%= @text %>
      </div>
    """
  end

  def heart(assigns) do
    ~H"""
    <%= unless is_nil(@points) do %>
      <%= for p <- 1..@points do %>
        <img src={~p"/images/heart_pink.svg"} class="heart" />
      <% end %>
    <% end %>
    """
  end

  def novelty(assigns) do
    ~H"""
      <div class="novelty__container">
        <div class="pie blue mask" style={"--p:#{max(5, floor((@track.track_novelty + @track.artist_novelty + @track.artist_novelty) / 3))}; --w:62px; --b:5px;"}>
          <div class="novelty__inner">
            <span class="novelty__title">
            Novelty
            </span>
            <span class="novelty__score">
              <%= floor((@track.track_novelty + @track.artist_novelty + @track.artist_novelty) / 3) %>
            </span>
          </div>
        </div>
      </div>
    """
  end

  def progress(assigns) do
    ~H"""
      <span class="progress">
        <%= if is_playing?(@track, @play_state) do %>
          <span class="progress__bar" style={"width: #{@progress}%"}></span>
        <% end %>
      </span>
    """
  end

  # Check if a track is playing
  def is_playing?(%Track{playing_since: playing}, %PlaybackState{state: :playing})
      when not is_nil(playing),
      do: true

  def is_playing?(_, _), do: false

  def is_playing?(track, play_state, _), do: is_playing?(track, play_state)
end
