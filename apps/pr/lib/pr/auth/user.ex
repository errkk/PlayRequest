defmodule PR.Auth.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field :display_name, :string
    field :email, :string
    field :first_name, :string
    field :image, :string
    field :last_name, :string
    field :token, :string

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:first_name, :last_name, :display_name, :token, :image, :email])
    |> validate_required([:token, :email])
  end

  def from_auth(%{
    credentials: %{token: token},
    info: %{
      first_name: first_name,
      last_name: last_name,
      image: image,
      email: email,
    }}) do
    %{
      first_name: first_name,
      last_name: last_name,
      image: image,
      email: email,
      token: token
    }
  end
end
