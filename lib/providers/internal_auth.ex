defmodule BtrzAuth.Providers.InternalAuth do
  @moduledoc """
  InternalAuthToken will generate tokens for internal services authentication
  """

  @doc """
  Gets a token with the internal options
  """
  @spec get_token() :: {:ok, Guardian.Token.token, Guardian.Token.claims} | {:error, any}
  def get_token() do
    #token_refresh_interval = :timer.seconds(60)
    #current_timestamp = :os.system_time(:millisecond)
    secret = Application.get_env(:btrz_auth, BtrzAuth.GuardianInternal)[:main_secret]
    BtrzAuth.GuardianInternal.encode_and_sign(%{}, %{}, [secret: secret, ttl: {2, :minutes}])
  end
end
