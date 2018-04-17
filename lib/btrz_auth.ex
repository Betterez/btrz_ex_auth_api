defmodule BtrzAuth do
  @moduledoc """
  BtrzAuth is the authentication api for the Betterez Elixir APIs.
  """

  @doc """
  Generates an internal token using the configuration main or secondary secret keys.

  It will return a token using the issuer passed by configuration and `%{}` claims.

  Options:

    * `issuer` - the issues for the token
    * `main_secret` - main secret key
    * `secondary_secret` - secondary secret key

  """
  @spec internal_auth_token(Keyword.t()) ::
          {:ok, Guardian.Token.token(), Guardian.Token.claims()} | {:error, any}
  def internal_auth_token(opts) do
    BtrzAuth.Providers.InternalAuth.get_token(opts)
  end
end
