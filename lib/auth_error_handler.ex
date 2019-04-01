defmodule BtrzAuth.AuthErrorHandler do
  @moduledoc false
  import Plug.Conn

  def auth_error(conn, {type, reason}, _opts) do
    try do
      body = Jason.encode!(%{error: type, reason: reason})

      conn
      |> put_resp_content_type("application/json")
      |> send_resp(:unauthorized, body)
    rescue
      _ ->
        body = Jason.encode!(%{error: "unauthenticated", reason: "unknown"})

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(:unauthorized, body)
    end
  end
end
