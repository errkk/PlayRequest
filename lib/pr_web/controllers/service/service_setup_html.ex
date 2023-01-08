defmodule PRWeb.Service.ServiceSetupHTML do
  use PRWeb, :html

  embed_templates "service_setup_html/*"

  def check(%{checked: true} = assigns) do
    ~H"""
      <img src={~p"/images/check.svg"} class="check" />
    """
  end

  def check(%{checked: false} = assigns) do
    ~H"""
      <span class="check--false">...</span>
    """
  end

  def check(assigns) do
    ~H"""
      <span class="check--false">...</span>
    """
  end

  def toggle(assigns) do
    ~H"""
      <.link href={@href} method="put">
        <%= if @is_active, do: "🙋‍♂️", else: "🙅‍♀️" %>
      </.link>
    """
  end
end

