defmodule PRWeb.AuthTest do
  use PR.DataCase, async: true

  alias PR.Auth

  test "Create auth with allowed email domain" do
    params = params_for(:user, email: "test@example.com", token: "123")
    {:ok, %Auth.User{}} = Auth.find_or_create_user(params)
  end
end

