defmodule BtrzAuth.Providers.InternalToken do
  @moduledoc """
  InternalTokenToken will generate tokens for internal services authentication
  """

  @doc """
  Gets a token with the internal options
  """
  @spec get_token(Keyword.t()) ::
          {:ok, Guardian.Token.token(), Guardian.Token.claims()} | {:error, any}
  def get_token(opts) do
    secret = Keyword.get(opts, :main_secret, "")
    BtrzAuth.Guardian.encode_and_sign(%{}, %{}, secret: secret, ttl: {30, :minutes})
  end
end
