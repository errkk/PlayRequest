defmodule PR.Factory do
  # with Ecto
  use ExMachina.Ecto, repo: PR.Repo


  def user_factory do
    %PR.Auth.User{
      first_name: "Jane",
      last_name: "Jane",
      email: sequence(:email, &"email-#{&1}@gmail.com"),
    }
  end
end

