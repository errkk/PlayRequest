defmodule PR.Auth.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias PR.Queue.Track

  # Tells JSON encoder what to serialise
  # User by PRWeb.Presence
  @derive {Jason.Encoder, only: [:first_name, :last_name, :image]}

  schema "users" do
    field(:display_name, :string)
    field(:email, :string)
    field(:first_name, :string)
    field(:image, :string)
    field(:last_name, :string)
    field(:token, :string)
    field(:is_trusted, :boolean)

    field(:points_received, :integer, virtual: true)

    has_many(:tracks, Track)

    timestamps()
  end

  @doc false
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:first_name, :last_name, :display_name, :token, :image, :email, :is_trusted])
    |> validate_required([:token, :email])
    |> unique_constraint(:email)
    |> validate_email_domain()
  end

  def from_auth(%{
        credentials: %{token: token},
        info: %{
          first_name: first_name,
          last_name: last_name,
          image: image,
          email: email
        }
      }) do
    %{
      first_name: first_name,
      last_name: last_name,
      image: image,
      email: email,
      token: token
    }
  end

  defp validate_email_domain(changeset) do
    if changeset
       |> get_change(:email)
       |> check_domain() do
      changeset
    else
      changeset
      |> add_error(:email, "wrong domain")
    end
  end

  defp check_domain(email) do
    get_allowed_domains()
    |> Enum.any?(&String.ends_with?(email, &1))
  end

  defp get_allowed_domains do
    :pr
    |> Application.get_env(:allowed_user_domains, "")
    |> String.split(",")
  end
end
