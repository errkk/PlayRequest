defmodule PRWeb.UserSocketToken do
  @moduledoc """
  Signing and verification of the token used to authenticate the user socket.
  """

  @salt "user socket"
  # Two weeks in seconds
  @max_age 1_209_600

  def sign(context, user_id), do: Phoenix.Token.sign(context, @salt, user_id)

  def verify(context, token),
    do: Phoenix.Token.verify(context, @salt, token, max_age: @max_age)
end
