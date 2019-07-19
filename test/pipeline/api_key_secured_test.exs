defmodule BtrzAuth.Pipeline.ApiKeySecuredTest do
  @moduledoc false
  use Plug.Test
  use ExUnit.Case, async: true

  alias BtrzAuth.Pipeline.ApiKeySecured

  defmodule ErrorHandler do
    @moduledoc false
    import Plug.Conn

    def auth_error(conn, {type, reason}) do
      body = inspect({type, reason})
      send_resp(conn, 401, body)
    end
  end

  defmodule Impl do
    @moduledoc false
    use Guardian, otp_app: :guardian

    def subject_for_token(%{id: id}, _claims), do: {:ok, id}
    def subject_for_token(%{"id" => id}, _claims), do: {:ok, id}

    def resource_from_claims(%{"sub" => id}), do: {:ok, %{id: id}}
  end

  defp underscore_data(data) do
    Enum.reduce(data, %{}, fn {key, val}, acc -> Map.put(acc, Macro.underscore(key), val) end)
  end

  setup do
    token_config = Application.get_env(:btrz_ex_auth_api, :token)
    impl = __MODULE__.Impl
    error_handler = __MODULE__.ErrorHandler

    conn =
      :get
      |> conn("/")

    {:ok, %{conn: conn, impl: impl, error_handler: error_handler, token_config: token_config}}
  end

  test "will use the x-api-key and will be authenticated",
       ctx do
    conn =
      ctx.conn
      |> put_req_header("x-api-key", "fa413eed-b4ef-4b4c-859b-693aaa31376d")
      |> ApiKeySecured.call(module: ctx.impl, error_handler: ctx.error_handler)

    refute conn.status == 401

    assert conn.private[:account] ==
             Keyword.get(ctx.token_config, :test_resource) |> underscore_data()
  end

  test "will return 401 if x-api-key header was not set",
       ctx do
    conn =
      ctx.conn
      |> ApiKeySecured.call(module: ctx.impl, error_handler: ctx.error_handler)

    assert conn.status == 401
  end
end
