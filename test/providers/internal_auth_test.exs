defmodule BtrzAuth.Providers.InternalAuthTest do
  use ExUnit.Case
  alias BtrzAuth.Providers.InternalAuth
  doctest InternalAuth

  test "get_token generates a binary token" do
    {:ok, token, _} = InternalAuth.get_token()
    assert is_binary(token) === true
  end
end
