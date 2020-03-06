defmodule PRWeb.CoronaVirusChannel do
  use PRWeb, :channel

  def join("mouse:position", _payload, socket) do
    if authorized?(socket) do
      {:ok, socket}
    else
      {:error, %{reason: "unauthorized"}}
    end
  end

  def handle_in("mouse:position", %{"x" => x, "y" => y}, socket) do
    broadcast!(socket, "mouse:position", %{x: x, y: y})
    {:noreply, socket}
  end

  # Add authorization logic here as required.
  defp authorized?(%{assigns: user_id}) when not is_nil(user_id) do
    true
  end

  defp authorized?(_) do
    false
  end
end
