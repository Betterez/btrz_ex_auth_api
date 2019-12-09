defmodule BtrzAuth.ErrorHandler do
  @moduledoc false
  import Plug.Conn

  def auth_error(conn, {_error, :secret_not_found}) do
    body = %{
      status: 400,
      code: "SECRET_NOT_FOUND",
      message: "Error getting the secret key"
    }

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(400, Jason.encode!(body))
  end

  def auth_error(conn, {type, reason}) do
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

  def validation_error(conn) do
    body = %{
      status: 400,
      code: "INVALID_PROVIDER_ID",
      message: "Error getting provider"
    }

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(400, Jason.encode!(body))
  end
end
