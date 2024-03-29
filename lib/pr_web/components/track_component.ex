defmodule PRWeb.TrackComponent do
  use PRWeb, :html

  import PRWeb.PlaybackComponents

  def tracks(assigns) do
    # Defaults for optional slots
    assigns =
      assigns
      |> assign_new(:chips, fn -> [] end)
      |> assign_new(:extra, fn -> [] end)

    ~H"""
    <%= for {track, i} <- @playlist |> Enum.with_index() do %>
      <div
        class={"
          track
          #{wobble?(track, @recently_liked)}
          #{if is_playing?(track, @play_state), do: " playing "}
          #{if dun_voted?(track), do: " has-voted is-liked "}
          #{if super_liked?(track), do: " has-super-liked "}
          #{if not is_nil(track.super_likes_received), do: " is-super-liked "}
        "}
        phx-mounted={JS.transition({"noop", "hide", "show"}, time: (i + 1) * 50)}
      >
        <div class="track__inner">
          <div class="track__img__container">
            <.particles :if={
              burnt?(track) or
                is_burnt?(track, @recently_liked) or
                not is_nil(track.burns_received)
            } />
            <img src={track.img} width="100" class="track__img" />
          </div>
          <div class="track__details">
            <%= render_slot(@details, track) %>
            <%= if @chips do %>
              <div class="chips">
                <%= render_slot(@chips, track) %>
              </div>
            <% end %>
          </div>
          <%= if @extra, do: render_slot(@extra, track) %>
        </div>
        <.progress track={track} play_state={@play_state} progress={@progress} />
      </div>
    <% end %>
    """
  end
end
