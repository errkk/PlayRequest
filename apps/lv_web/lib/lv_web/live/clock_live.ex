defmodule EWeb.ClockLive do
  use Phoenix.LiveView
  import Calendar.Strftime

  def render(assigns) do
    ~L"""
    <div>
      <h2 phx-click="watdis"><%= if assigns[:msg], do: @msg, else: "Wat dis?" %></h2>
      <h2 phx-click="boom">It's <%= strftime!(@date, "%r") %></h2>
      <p>
      wat - dis cool
      </p>
    </div>
    """
  end

  def mount(_session, socket) do
    if connected?(socket), do: :timer.send_interval(1000, self(), :tick)

    {:ok, put_date(socket)}
  end

  def handle_info(:tick, socket) do
    {:noreply, put_date(socket)}
  end

  def handle_event("nav", _path, socket) do
    {:noreply, socket}
  end

  def handle_event("watdis", _, socket) do
    IO.inspect "it pressed"
    {:noreply, assign(socket, msg: "oh dat")}
  end

  defp put_date(socket) do
    assign(socket, date: :calendar.local_time())
  end
end

