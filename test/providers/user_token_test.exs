defmodule BtrzAuth.Providers.UserTokenTest do
  use ExUnit.Case
  alias BtrzAuth.Providers.UserToken
  doctest UserToken

  @user %{"id" => "123", "name" => "Thei"}
  @secret "my_secret"

  test "get_token generates a binary token" do
    {:ok, token, _} = UserToken.get_token(@user, secret: @secret)
    assert is_binary(token) === true
  end

  test "get_token token decoded using a user resource and 'btrz-api-accounts' issuer" do
    secret = "my_secret"
    {:ok, token, _} = UserToken.get_token(@user, secret: @secret)
    {:ok, resource, claims} = BtrzAuth.GuardianUser.resource_from_token(token, %{}, secret: @secret)
    assert resource == @user
    assert claims["iss"] == "btrz-api-accounts"
  end
end
