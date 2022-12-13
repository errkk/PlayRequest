defmodule PRWeb.PlaybackComponents do
  use PRWeb, :html

  alias PR.Queue.Track
  alias PR.Music.PlaybackState
  
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
        <div class="pie blue mask" style={"--p:#{max(5, @score)}; --w:62px; --b:5px;"}>
          <div class="novelty__inner">
            <span class="novelty__title">
              Novelty
            </span>
            <span class="novelty__score">
              <%= @score %>
            </span>
          </div>
        </div>
      </div>
    """
  end

  def progress(assigns) do
    ~H"""
      <%= if is_playing?(@track, @play_state) do %>
        <span class="progress">
          <span class="progress__bar" style={"width: #{@progress}%"}></span>
        </span>
      <% end %>
    """
  end

  # Check if a track is playing
  def is_playing?(%Track{playing_since: playing}, %PlaybackState{state: :playing})
      when not is_nil(playing),
      do: true

  def is_playing?(_, _), do: false

  def is_playing?(track, play_state, _), do: is_playing?(track, play_state)

  def get_track_novelty(%Track{track_novelty: track_novelty, artist_novelty: artist_novelty}) do
    floor((track_novelty + artist_novelty + artist_novelty) / 3)
  end
end
