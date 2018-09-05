defmodule BtrzAuthTest do
  use ExUnit.Case

  @user %{"id" => "123", "name" => "Thei"}
  @secret "my_secret"

  test "internal token decoded using %{} as resource and 'btrz-api-client' issuer" do
    {:ok, token, _} = BtrzAuth.internal_auth_token(Application.get_env(:btrz_ex_auth_api, :token))

    {:ok, resource, claims} =
      BtrzAuth.Guardian.resource_from_token(
        token,
        %{},
        secret: Application.get_env(:btrz_ex_auth_api, :token)[:main_secret]
      )

    assert resource == %{}
    assert claims["iss"] == "btrz-api-client"
  end

  test "token decoded using custom claims" do
    {:ok, token, _} =
      BtrzAuth.user_auth_token(@user, secret: @secret, claims: %{"myclaim" => true})

    {:ok, resource, claims} =
      BtrzAuth.GuardianUser.resource_from_token(token, %{"myclaim" => true}, secret: @secret)

    assert resource == @user["id"]
    assert claims["iss"] == "btrz-api-accounts"
  end
end
