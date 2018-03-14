defmodule BtrzAuth do
  @moduledoc """
  BtrzAuth is the authentication api for the Betterez Elixir APIs.
  """

  @doc """
  Generates an internal token using the configuration main or secondary secret keys.

  It will return a token using the issuer passed by configuration and `%{}` claims.
  """
  @spec internal_auth_token() :: {:ok, Guardian.Token.token, Guardian.Token.claims} | {:error, any}
  def internal_auth_token() do
    BtrzAuth.Providers.InternalAuth.get_token()
  end
end
