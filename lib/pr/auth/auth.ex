defmodule PR.Auth do
  @moduledoc """
  The Auth context.
  """

  import Ecto.Query, warn: false
  alias PR.Repo

  alias PR.Auth.User

  def list_users do
    Repo.all(User)
  end

  def get_user!(id), do: Repo.get!(User, id)
  def get_user(id), do: Repo.get(User, id)

  def find_or_create_user(%{email: email} = params) do
    case Repo.get_by(User, email: email) do
      nil ->
        create_user(params)
      %User{} = user ->
        {:ok, user}
    end
  end

  def update_user(%User{} = user, attrs) do
    user
    |> User.changeset(attrs)
    |> Repo.update()
  end

  def delete_user(%User{} = user) do
    Repo.delete(user)
  end

  def change_user(%User{} = user) do
    User.changeset(user, %{})
  end

  defp create_user(attrs \\ %{}) do
    %User{}
    |> User.changeset(attrs)
    |> Repo.insert()
  end
end
