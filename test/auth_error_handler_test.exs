defmodule BtrzAuth.AuthErrorHandlerTest do
  use ExUnit.Case
  use Plug.Test

  alias BtrzAuth.AuthErrorHandler

  describe("#auth_error") do

    test "sends 401 resp with {message: <type>} json as body" do
      conn = conn(:get, "/test")
      conn = AuthErrorHandler.auth_error(conn, {:unauthorized, nil}, nil)

      assert conn.status == 401
      assert conn.resp_body == Poison.encode!(%{message: "unauthorized"})
    end

  end
end
