defmodule BtrzAuth.ErrorHandlerTest do
  use ExUnit.Case
  use Plug.Test

  alias BtrzAuth.ErrorHandler

  describe "#auth_error" do
    test "sends 401 resp with {error, reason} json as body" do
      conn = conn(:get, "/test")
      conn = ErrorHandler.auth_error(conn, {:unauthorized, :x_not_found})

      assert conn.status == 401
      assert conn.resp_body == Jason.encode!(%{error: "unauthorized", reason: "x_not_found"})
    end
  end
end
