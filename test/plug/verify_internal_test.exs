defmodule BtrzAuth.Plug.VerifyInternalTest do
  @moduledoc false

  use Plug.Test
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  alias BtrzAuth.Plug.{VerifyInternal, VerifyToken}

  @user_id "000000000000000000000001"

  defp refused?(conn) do
    conn.halted and conn.status == 401 and
      Jason.decode!(conn.resp_body) == %{
        "error" => "unauthorized",
        "reason" => "internal_token_required"
      }
  end

  describe "call/2 with the private data VerifyToken stores" do
    defp call(token_type, private) do
      conn =
        :post
        |> conn("/")
        |> put_private(:btrz_token_type, token_type)

      private
      |> Enum.reduce(conn, fn {key, value}, conn -> put_private(conn, key, value) end)
      |> VerifyInternal.call(VerifyInternal.init())
    end

    test "lets an internal token through" do
      conn = call(:internal, %{})
      refute conn.halted
    end

    test "refuses a back-office user token" do
      capture_log(fn ->
        assert refused?(call(:user, %{user_id: @user_id, user_aud: "betterez-app"}))
      end)
    end

    test "refuses a customer token" do
      capture_log(fn -> assert refused?(call(:user, %{user_id: nil, user_aud: "customer"})) end)
    end

    test "refuses the test token" do
      capture_log(fn -> assert refused?(call(:test, %{user_id: @user_id})) end)
    end

    test "refuses a request VerifyToken did not run on" do
      capture_log(fn -> assert refused?(call(nil, %{})) end)
    end
  end

  describe "after VerifyToken, with signed tokens" do
    setup do
      token_config = Application.get_env(:btrz_ex_auth_api, :token)

      conn =
        :post
        |> conn("/")
        |> put_private(:account, Keyword.get(token_config, :test_resource, %{}))

      {:ok, %{conn: conn, token_config: token_config}}
    end

    defp verify(ctx, token) do
      ctx.conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> VerifyToken.call(VerifyToken.init())
      |> VerifyInternal.call(VerifyInternal.init())
    end

    test "lets an internal token through", ctx do
      {:ok, token, _claims} = BtrzAuth.internal_auth_token(ctx.token_config)

      conn = verify(ctx, token)

      refute conn.halted
      assert conn.private.btrz_token_type == :internal
    end

    test "refuses a back-office user token", ctx do
      {:ok, token, _claims} =
        BtrzAuth.GuardianUser.encode_and_sign(
          %{"id" => @user_id},
          %{"id" => @user_id, "aud" => "betterez-app"},
          secret: ctx.token_config[:test_resource]["private_key"]
        )

      capture_log(fn ->
        conn = verify(ctx, token)
        assert conn.private.btrz_token_type == :user
        assert refused?(conn)
      end)
    end
  end
end
