defmodule PR.ExternalAuth do
  @moduledoc """
  The Sonos context.
  """

  import Ecto.Query, warn: false
  alias PR.Repo

  alias PR.ExternalAuth.Auth

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
      nil -> %Auth{service: service}
      auth -> auth
    end
    |> Auth.changeset(changes)
    |> Repo.insert_or_update()
  rescue
    Ecto.StaleEntryError ->
      # A concurrent token refresh discarded the row between our read and
      # update. The token we have is fresh, so re-insert it.
      %Auth{service: service}
      |> Auth.changeset(changes)
      |> Repo.insert()
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

  def discard_auth(service) when is_atom(service) do
    service
    |> Atom.to_string()
    |> discard_auth()
  end

  def discard_auth(service) do
    case get_auth(service) do
      %Auth{} = auth -> delete_auth(auth)
      _ -> {:ok, nil}
    end
  end

  def change_auth(%Auth{} = auth) do
    Auth.changeset(auth, %{})
  end
end
