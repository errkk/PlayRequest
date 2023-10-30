defmodule PRWeb.Layouts do
  use PRWeb, :html

  embed_templates("layouts/*")

  def ghost(assigns) do
      ~H"""
        <.ghost_shader />
      """
  end
end
