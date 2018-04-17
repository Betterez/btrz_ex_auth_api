defmodule BtrzAuth.Services.AccountsTest do
  use ExUnit.Case, async: true

  test "get_application/2 returns the application of the api-key" do
    assert {:ok, _body} =
             BtrzAuth.Services.Accounts.get_application(
               "test-api-key",
               "get"
             )
  end

  test "get_application/2 returns 'not found' if 404" do
    assert {:error, %{status_code: 404}} =
             BtrzAuth.Services.Accounts.get_application(
               "test-api-key",
               "status/404"
             )
  end

  test "get_application/2 returns error with another HTTP error than 404" do
    assert {:error, %{status_code: 500}} =
             BtrzAuth.Services.Accounts.get_application(
               "test-api-key",
               "status/500"
             )
  end
end
