defmodule BtrzAuth.Providers.UserTokenTest do
  use ExUnit.Case
  alias BtrzAuth.Providers.UserToken
  doctest UserToken

  @user %{"id" => "123", "name" => "Thei"}
  @secret "my_secret"

  describe "get_token/3" do
    test "generates a binary token" do
      {:ok, token, _} = UserToken.get_token(@user, secret: @secret)
      assert is_binary(token) === true
    end

    test "token decoded using a user resource and 'btrz-api-accounts' issuer" do
      {:ok, token, _} = UserToken.get_token(@user, secret: @secret)

      {:ok, resource, claims} =
        BtrzAuth.GuardianUser.resource_from_token(token, %{}, secret: @secret)

      assert resource == @user["id"]
      assert claims["iss"] == "btrz-api-accounts"
    end

    test "token decoded using custom claims" do
      {:ok, token, _} = UserToken.get_token(@user, secret: @secret, claims: %{"myclaim" => true})

      {:ok, resource, claims} =
        BtrzAuth.GuardianUser.resource_from_token(token, %{"myclaim" => true}, secret: @secret)

      assert resource == @user["id"]
      assert claims["iss"] == "btrz-api-accounts"
    end
  end
end
