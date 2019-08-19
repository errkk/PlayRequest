defmodule E.SonosAuth do
  @moduledoc """
  The Sonos context.
  """

  import Ecto.Query, warn: false
  alias E.Repo

  alias E.SonosAuth.Auth

  def list_tokens do
    Repo.all(Auth)
  end

  def get_auth() do
    Auth
    |> order_by([a], desc: a.activated_at)
    |> limit(1)
    |> Repo.one()
  end

  def create_auth(attrs \\ %{}) do
    %Auth{}
    |> Auth.changeset(attrs)
    |> Repo.insert()
  end

  def update_auth(%Auth{} = auth, attrs) do
    auth
    |> Auth.changeset(attrs)
    |> Repo.update()
  end

  def delete_auth(%Auth{} = auth) do
    Repo.delete(auth)
  end

  def change_auth(%Auth{} = auth) do
    Auth.changeset(auth, %{})
  end
end
