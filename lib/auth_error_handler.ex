defmodule BtrzAuth.AuthErrorHandler do
  import Plug.Conn

  def auth_error(conn, {type, reason}, _opts) do
    try do
      body = Poison.encode!(%{error: type, reason: reason})
      send_resp(conn, 401, body)
    rescue
      _ ->
        send_resp(conn, 401, Poison.encode!(%{error: "unauthenticated", reason: "unknown"}))
    end
  end
end
