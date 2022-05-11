defmodule PR.ExternalAuth.Auth do
  use Ecto.Schema
  import Ecto.Changeset
  alias OAuth2.AccessToken

  alias PR.ExternalAuth.Auth

  schema "tokens" do
    field :access_token, :string
    field :refresh_token, :string
    field :service, :string
    field :activated_at, :utc_datetime

    timestamps()
  end

  @fields [:access_token, :refresh_token, :service, :activated_at]

  @doc false
  def changeset(auth, attrs) do
    auth
    |> cast(attrs, @fields)
    |> validate_required(@fields)
  end

  def to_token(%Auth{} = auth) do
    auth
    |> Map.take([:access_token, :refresh_token])
    |> Map.Helpers.stringify_keys()
    |> AccessToken.new()
  end
end
