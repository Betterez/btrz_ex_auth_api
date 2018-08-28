defmodule BtrzAuth.AuthErrorHandlerTest do
  use ExUnit.Case
  use Plug.Test

  alias BtrzAuth.AuthErrorHandler

  describe "#auth_error" do
    test "sends 401 resp with {error, reason} json as body" do
      conn = conn(:get, "/test")
      conn = AuthErrorHandler.auth_error(conn, {:unauthorized, :x_not_found}, nil)

      assert conn.status == 401
      assert conn.resp_body == Poison.encode!(%{error: "unauthorized", reason: "x_not_found"})
    end
  end
end
