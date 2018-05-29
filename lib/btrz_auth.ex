defmodule BtrzAuth do
  @moduledoc """
  BtrzAuth is the authentication api for the Betterez Elixir APIs.
  """

  @doc """
  Generates an internal token using the configuration main or secondary secret keys.

  It will return a token using the issuer passed by configuration and `%{}` claims.

  Options:

    * `issuer` - the issuer of the token
    * `main_secret` - main secret key
    * `secondary_secret` - secondary secret key

  """
  @spec internal_auth_token(Keyword.t()) ::
          {:ok, Guardian.Token.token(), Guardian.Token.claims()} | {:error, any}
  def internal_auth_token(opts) do
    BtrzAuth.Providers.InternalToken.get_token(opts)
  end

  @doc """
  Generates an user token using the configuration ecret keys.

  It will return a token using the the user and the issuer passed by configuration and `%{}` claims.

  Options:

    * `issuer` - the issuer of the token
    * `secret` - secret key

  """
  @spec user_auth_token(Map.t(), Keyword.t()) ::
          {:ok, Guardian.Token.token(), Guardian.Token.claims()} | {:error, any}
  def user_auth_token(user, opts) do
    BtrzAuth.Providers.UserToken.get_token(user, opts)
  end
end
