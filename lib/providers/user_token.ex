defmodule BtrzAuth.Providers.UserToken do
  @moduledoc """
  UserToken will generate tokens for users authentication
  """

  @doc """
  Gets a token for the user with the options
  """
  @spec get_token(Map.t(), Keyword.t()) ::
          {:ok, Guardian.Token.token(), Guardian.Token.claims()} | {:error, any}
  def get_token(user, opts) do
    secret = Keyword.get(opts, :secret, "")
    BtrzAuth.GuardianUser.encode_and_sign(user, %{}, secret: secret, ttl: {2, :minutes})
  end
end
