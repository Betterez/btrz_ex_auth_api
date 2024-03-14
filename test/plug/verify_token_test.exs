defmodule BtrzAuth.Plug.VerifyTokenTest do
  @moduledoc false

  use Plug.Test

  alias BtrzAuth.Plug.VerifyToken

  use ExUnit.Case, async: true

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

  @resource %{"id" => "2dSWOd35475656342wsdf23qwq"}

  describe "init/1" do
    test "will use the config keys and default realm" do
      opts = VerifyToken.init()
      assert opts[:main_secret] == Application.get_env(:btrz_ex_auth_api, :token)[:main_secret]

      assert opts[:secondary_secret] ==
               Application.get_env(:btrz_ex_auth_api, :token)[:secondary_secret]

      assert opts[:realm_reg] == ~r/Bearer:? +(.*)$/i
    end

    test "will use the config keys and realm" do
      opts = VerifyToken.init(realm: "test", any: true)
      assert opts[:main_secret] == Application.get_env(:btrz_ex_auth_api, :token)[:main_secret]

      assert opts[:secondary_secret] ==
               Application.get_env(:btrz_ex_auth_api, :token)[:secondary_secret]

      assert opts[:any] == true
      assert opts[:realm_reg] == ~r/test:? +(.*)$/i
    end
  end

  describe "call/2" do
    setup do
      token_config = Application.get_env(:btrz_ex_auth_api, :token)
      impl = __MODULE__.Impl
      error_handler = __MODULE__.ErrorHandler

      conn =
        :get
        |> conn("/")
        |> put_private(:account, Keyword.get(token_config, :test_resource, %{}))

      {:ok, %{conn: conn, impl: impl, error_handler: error_handler, token_config: token_config}}
    end

    test "will use the main key and will be authenticated", ctx do
      opts = VerifyToken.init()

      secret = ctx.token_config[:main_secret]
      {:ok, token, _claims} = __MODULE__.Impl.encode_and_sign(@resource, %{}, secret: secret)

      conn =
        ctx.conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> VerifyToken.call(opts ++ [module: ctx.impl, error_handler: ctx.error_handler])

      refute conn.status == 401
      assert conn.private[:btrz_token_type] == :internal
    end

    test "will use the secondary key and will be authenticated", ctx do
      opts = VerifyToken.init()

      secret = ctx.token_config[:secondary_secret]
      {:ok, token, _claims} = __MODULE__.Impl.encode_and_sign(@resource, %{}, secret: secret)

      conn =
        ctx.conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> VerifyToken.call(opts ++ [module: ctx.impl, error_handler: ctx.error_handler])

      refute conn.status == 401
      assert conn.private[:btrz_token_type] == :internal
    end

    test "will use the user token with the private key (not internal) and will be authenticated",
         ctx do
      opts = VerifyToken.init()

      secret = ctx.token_config[:test_resource]["private_key"]

      {:ok, token, _claims} =
        BtrzAuth.GuardianUser.encode_and_sign(
          @resource,
          %{"id" => @resource["id"]},
          secret: secret
        )

      conn =
        ctx.conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> VerifyToken.call(opts ++ [module: ctx.impl, error_handler: ctx.error_handler])

      refute conn.status == 401
      assert conn.private[:user_id] == @resource["id"]
      assert conn.private[:btrz_token_type] == :user
    end

    test "will return 401 if token not found", ctx do
      opts = VerifyToken.init()

      conn =
        ctx.conn
        |> VerifyToken.call(opts ++ [module: ctx.impl, error_handler: ctx.error_handler])

      assert conn.status == 401
    end

    test "will return 401 if token not valid", ctx do
      opts = VerifyToken.init()

      secret = "not_valid"
      {:ok, token, _claims} = __MODULE__.Impl.encode_and_sign(@resource, %{}, secret: secret)

      conn =
        ctx.conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> VerifyToken.call(opts ++ [module: ctx.impl, error_handler: ctx.error_handler])

      assert conn.status == 401
    end

    @tag :skip
    test "will return 400 if secret is nil when decode_and_verify", ctx do
      opts = VerifyToken.init()
      opts = Keyword.put(opts, :main_secret, nil)
      opts = Keyword.put(opts, :secondary_secret, nil)

      secret = ctx.token_config[:main_secret]
      {:ok, token, _claims} = __MODULE__.Impl.encode_and_sign(@resource, %{}, secret: secret)
      IO.inspect(token)

      conn =
        ctx.conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> VerifyToken.call(opts ++ [module: ctx.impl, error_handler: BtrzAuth.ErrorHandler])

      IO.inspect(opts++[module: ctx.impl, error_handler: BtrzAuth.ErrorHandler])
      assert conn.status == 400
      resp_body = Jason.decode!(conn.resp_body)
      assert resp_body["code"] == "SECRET_NOT_FOUND"
      assert resp_body["status"] == 400
    end

    test "will be authenticated with user token and premium claim",
         ctx do
      valid_claims = %{webhooks: true, loyalty: false, id: @resource["id"]}
      opts = VerifyToken.init(claims: %{webhooks: true})

      secret = ctx.token_config[:test_resource]["private_key"]

      {:ok, token, _claims} =
        BtrzAuth.GuardianUser.encode_and_sign(@resource, valid_claims, secret: secret)

      conn =
        ctx.conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> VerifyToken.call(opts ++ [module: ctx.impl, error_handler: ctx.error_handler])

      refute conn.status == 401
      assert conn.private[:user_id] == @resource["id"]
      assert conn.private[:btrz_token_type] == :user
    end

    test "will return 401 if the user token is not validated with the premium claim",
         ctx do
      valid_claims = %{webhooks: true, loyalty: false}
      opts = VerifyToken.init(claims: valid_claims)

      secret = ctx.token_config[:test_resource]["private_key"]

      {:ok, token, _claims} =
        BtrzAuth.GuardianUser.encode_and_sign(
          @resource,
          %{loyalty: false, another: true},
          secret: secret
        )

      conn =
        ctx.conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> VerifyToken.call(opts ++ [module: ctx.impl, error_handler: ctx.error_handler])

      assert conn.status == 401
    end
  end
end
