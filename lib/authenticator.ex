defmodule BtrzAuth.Authenticator do
  @moduledoc """
  BtrzAuth is the authentication api for the Betterez Elixir APIs.
  """

  @doc """
  get_token

  ## Examples

      iex> BtrzAuth.InternalAuthToken.get_token
      "a_token"

  """
  def get_token() do
    BtrzAuth.Guardian.encode_and_sign(%{id: "1234", name: "test"}, %{}, ttl: {2, :minutes})
  end
end
