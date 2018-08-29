defmodule BtrzAuth.AuthErrorHandler do
  import Plug.Conn

  def auth_error(conn, {type, reason}, _opts) do
    try do
      body = Poison.encode!(%{error: type, reason: reason})

      conn
      |> put_resp_content_type("application/json")
      |> send_resp(:unauthorized, body)
    rescue
      _ ->
        body = Poison.encode!(%{error: "unauthenticated", reason: "unknown"})

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(:unauthorized, body)
    end
  end
end
