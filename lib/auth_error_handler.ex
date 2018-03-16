defmodule BtrzAuth.AuthErrorHandler do
  import Plug.Conn

  def auth_error(conn, {type, reason}, _opts) do
    body = Poison.encode!(%{error: type, reason: reason})
    send_resp(conn, 401, body)
  end
end
