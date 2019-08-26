defmodule E.ExternalAuth do
  @moduledoc """
  The Sonos context.
  """

  import Ecto.Query, warn: false
  alias E.Repo

  alias E.ExternalAuth.Auth

  def list_tokens do
    Repo.all(Auth)
  end

  def get_auth(service) when is_atom(service) do
    service
    |> Atom.to_string()
    |> get_auth()
  end

  def get_auth(service) do
    Repo.get_by(Auth, service: service)
  end

  def insert_or_update_auth(%{"service" => service} = changes) do
    case Repo.get_by(Auth, service: service) do
      nil  -> %Auth{service: service}
      auth -> auth
    end
    |> Auth.changeset(changes)
    |> IO.inspect
    |> Repo.insert_or_update()
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
