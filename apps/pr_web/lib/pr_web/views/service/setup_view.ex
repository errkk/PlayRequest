defmodule PRWeb.Service.ServiceSetupView do
  use PRWeb, :view

  def check do
    content_tag(:span, "...", class: "check--false")
  end

  def check(true) do
    img_tag("/images/check.svg", class: "check")
  end

  def check(false) do
    content_tag(:span, "", class: "check--false")
  end
end
