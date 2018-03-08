defmodule BtrzAuthTest.InternalAuthTokenTest do
  use ExUnit.Case
  alias BtrzAuth.InternalAuthToken
  doctest InternalAuthToken

  test "get_token generates a binary token" do
    {:ok, token, _} = InternalAuthToken.get_token()
    assert is_binary(token) === true
  end
end
