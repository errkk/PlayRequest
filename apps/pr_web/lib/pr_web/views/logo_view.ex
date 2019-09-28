defmodule PRWeb.LogoView do
  use PRWeb, :view

  alias PR.Music.PlaybackState

  def logo(%PlaybackState{state: :playing}) do
    img_tag(Routes.static_path(PRWeb.Endpoint, "/images/playing.svg"), class: "logo")
  end

  def logo(_) do
    img_tag(Routes.static_path(PRWeb.Endpoint, "/images/not-playing.svg"), class: "logo")
  end
end
