defmodule BtrzAuth.Pipeline.TokenSecuredTest do
  @moduledoc false
  use Plug.Test
  use ExUnit.Case, async: true

  alias BtrzAuth.Pipeline.TokenSecured

  defmodule ErrorHandler do
    @moduledoc false
    import Plug.Conn

    def auth_error(conn, {type, reason}, _opts) do
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

  @resource %{"id" => "2dSWOd35475656342wsdf23qwq"}
  @valid_claim %{"id" => "2dSWOd35475656342wsdf23qwq"}

  setup do
    token_config = Application.get_env(:btrz_ex_auth_api, :token)
    impl = __MODULE__.Impl
    error_handler = __MODULE__.ErrorHandler

    conn =
      :get
      |> conn("/")
      |> put_req_header("x-api-key", "fa413eed-b4ef-4b4c-859b-693aaa31376d")
      |> put_private(:application, Keyword.get(token_config, :test_resource, %{}))

    {:ok, %{conn: conn, impl: impl, error_handler: error_handler, token_config: token_config}}
  end

  test "will use the user token and will be authenticated",
       ctx do
    secret = ctx.token_config[:test_resource]["privateKey"]

    {:ok, token, _claims} =
      BtrzAuth.GuardianUser.encode_and_sign(@resource, @valid_claim, secret: secret)

    conn =
      ctx.conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> TokenSecured.call(module: ctx.impl, error_handler: ctx.error_handler)

    refute conn.status == 401
    assert conn.private[:user_id] == @resource["id"]
  end

  test "will be authenticated with any claim",
       ctx do
    secret = ctx.token_config[:test_resource]["privateKey"]

    {:ok, token, _claims} =
      BtrzAuth.GuardianUser.encode_and_sign(
        @resource,
        %{"custom_claim" => "houh", "id" => @resource["id"]},
        secret: secret
      )

    conn =
      ctx.conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> TokenSecured.call(module: ctx.impl, error_handler: ctx.error_handler)

    refute conn.status == 401
    assert conn.private[:user_id] == @resource["id"]
  end

  test "will return 401 if x-api-key header was not set",
       ctx do
    secret = ctx.token_config[:test_resource]["privateKey"]

    {:ok, token, _claims} =
      BtrzAuth.GuardianUser.encode_and_sign(@resource, @valid_claim, secret: secret)

    conn =
      ctx.conn
      |> delete_req_header("x-api-key")
      |> put_req_header("authorization", "Bearer #{token}")
      |> TokenSecured.call(module: ctx.impl, error_handler: ctx.error_handler)

    assert conn.status == 401
  end
end
