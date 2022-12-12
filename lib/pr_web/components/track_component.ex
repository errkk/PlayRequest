defmodule PRWeb.TrackComponent do
  use PRWeb, :html

  alias PR.Queue.Track
  alias PR.Music.PlaybackState

  # Get helper functions like dun_voted etc 
  import PRWeb.PlaybackView
  # For heart function
  import PRWeb.SharedView

  def track(assigns) do
    ~H"""
    <div class={"track #{wobble?(@recently_liked, @track)}#{if playing?(@track, @play_state), do: "playing"} #{if dun_voted?(@track), do: "has-voted"}"}>
        <div class="track__inner">
            <div class="track__img__container">

            <%= if can_vote?(@track, @current_user) do %>
              <button class="flip__container animate" phx-click="like" value={@track.id} title={"Give some appreciation to #{name @track.user}"}>
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
                <%= if playing?(@track, @play_state) do %>
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
                <div class="chip">
                  <img src={@track.user.image} width="40" class="chip__img" />
                  <%= name @track.user %>
                </div>

                <%= heart @track %>
              </div>
            </div>
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
          </div>
        <.progress track={@track} play_state={@play_state} progress={@progress} />
      </div>
    """
  end

  def progress(%{
      progress: progress,
      play_state: play_state,
      track: %{duration: duration} = track,
    } = assigns)
      when is_number(progress) do

    value = map_range(progress, 0, duration, 0, 100)

    if playing?(track, play_state) do
    ~H"""
      <span class="progress">
        <span class="progress__bar" style={"width: #{value}%"}></span>
      </span>
    """
    end
  end

  def progress(assigns), do: nil

  defp map_range(x, in_min, in_max, out_min, out_max) do
    (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min
  end

  # Check if a track is playing
  defp playing?(%Track{playing_since: playing}, %PlaybackState{state: :playing})
      when not is_nil(playing),
      do: true
end
