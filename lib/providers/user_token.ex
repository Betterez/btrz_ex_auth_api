defmodule BtrzAuth.Providers.UserToken do
  @moduledoc """
  UserToken will generate tokens for users authentication
  """

  @doc """
  Gets a token for the user with the options.

  Options may include:
   * `secret` - secret key for generating your token.
   * `claims` - custom claims for your token. Default %{}.
  """
  @spec get_token(Map.t(), Keyword.t()) ::
          {:ok, Guardian.Token.token(), Guardian.Token.claims()} | {:error, any}
  def get_token(user, opts) do
    secret = Keyword.get(opts, :secret, "")
    claims = Keyword.get(opts, :claims, %{})
    BtrzAuth.GuardianUser.encode_and_sign(user, claims, secret: secret, ttl: {2, :days})
  end
end
