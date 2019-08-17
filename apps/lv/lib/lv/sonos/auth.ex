defmodule E.Sonos.Auth do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tokens" do
    field :access_token, :string
    field :refresh_token, :string
    field :activated_at, :utc_datetime

    timestamps()
  end

  @fields [:access_token, :refresh_token, :activated_at]

  @doc false
  def changeset(auth, attrs) do
    auth
    |> cast(attrs, @fields)
    |> validate_required(@fields)
  end
end
