defmodule BtrzAuth.Providers.InternalAuth do
  @moduledoc """
  InternalAuthToken will generate tokens for internal services authentication
  """

  @doc """
  Gets a token with the internal options
  """
  @spec get_token() :: {:ok, Guardian.Token.token, Guardian.Token.claims} | {:error, any}
  def get_token() do
    secret = Application.get_env(:btrz_auth, :token)[:main_secret]
    BtrzAuth.GuardianInternal.encode_and_sign(%{}, %{}, [secret: secret, ttl: {2, :minutes}])
  end
end
