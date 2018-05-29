defmodule BtrzAuth.Providers.InternalTokenTest do
  use ExUnit.Case
  alias BtrzAuth.Providers.InternalToken
  doctest InternalToken

  test "get_token generates a binary token" do
    {:ok, token, _} = InternalToken.get_token(Application.get_env(:btrz_ex_auth_api, :token))
    assert is_binary(token) === true
  end

  test "get_token token decoded using %{} as resource and 'btrz-api-client' issuer" do
    {:ok, token, _} = InternalToken.get_token(Application.get_env(:btrz_ex_auth_api, :token))

    {:ok, resource, claims} =
      BtrzAuth.Guardian.resource_from_token(
        token,
        %{},
        secret: Application.get_env(:btrz_ex_auth_api, :token)[:main_secret]
      )

    assert resource == %{}
    assert claims["iss"] == "btrz-api-client"
  end
end
