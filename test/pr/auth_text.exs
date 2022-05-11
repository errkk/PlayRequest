defmodule PRWeb.AuthTest do
  use PRWeb.DataCase

  alias PR.Auth

  test "Create auth with allowed email domain" do
    params = params_for(:user, email: "test@gmail.com")
    Auth.find_or_create_user(params)
    |> IO.inspect
  end
end

