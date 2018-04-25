defmodule BtrzAuth.Plug.VerifyTokenTest do
  @moduledoc false

  use Plug.Test

  alias BtrzAuth.Plug.VerifyToken

  use ExUnit.Case, async: true

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

  @resource %{id: "bobby"}

  describe "init/1" do
    test "will use the config keys and default realm" do
      opts = VerifyToken.init()
      assert opts[:main_secret] == Application.get_env(:btrz_auth, :token)[:main_secret]
      assert opts[:secondary_secret] == Application.get_env(:btrz_auth, :token)[:secondary_secret]
      assert opts[:realm_reg] == ~r/Bearer:? +(.*)$/i
    end

    test "will use the config keys and realm" do
      opts = VerifyToken.init(realm: "test")
      assert opts[:main_secret] == Application.get_env(:btrz_auth, :token)[:main_secret]
      assert opts[:secondary_secret] == Application.get_env(:btrz_auth, :token)[:secondary_secret]
      assert opts[:realm_reg] == ~r/test:? +(.*)$/i
    end
  end

  describe "call/2 using internal token" do
    setup do
      token_config = Application.get_env(:btrz_auth, :token)
      impl = __MODULE__.Impl
      error_handler = __MODULE__.ErrorHandler

      conn =
        :get
        |> conn("/")
        |> put_private(:auth_user, Keyword.get(token_config, :test_resource, %{}))

      {:ok, %{conn: conn, impl: impl, error_handler: error_handler, token_config: token_config}}
    end

    test "will use the main key and will be authenticated", ctx do
      opts = VerifyToken.init()

      secret = ctx.token_config[:main_secret]
      {:ok, token, claims} = __MODULE__.Impl.encode_and_sign(@resource, %{}, secret: secret)

      conn =
        ctx.conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> VerifyToken.call(opts ++ [module: ctx.impl, error_handler: ctx.error_handler])

      refute conn.status == 401
    end

    test "will use the secondary key and will be authenticated", ctx do
      opts = VerifyToken.init()

      secret = ctx.token_config[:secondary_secret]
      {:ok, token, claims} = __MODULE__.Impl.encode_and_sign(@resource, %{}, secret: secret)

      conn =
        ctx.conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> VerifyToken.call(opts ++ [module: ctx.impl, error_handler: ctx.error_handler])

      refute conn.status == 401
    end

    test "will use the user token with the private key (not internal) and will be authenticated", ctx do
      opts = VerifyToken.init()

      secret = ctx.token_config[:test_resource]["privateKey"]
      {:ok, token, claims} = __MODULE__.Impl.encode_and_sign(@resource, %{}, secret: secret)

      conn =
        ctx.conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> VerifyToken.call(opts ++ [module: ctx.impl, error_handler: ctx.error_handler])

      refute conn.status == 401
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
      {:ok, token, claims} = __MODULE__.Impl.encode_and_sign(@resource, %{}, secret: secret)

      conn =
        ctx.conn
        |> put_req_header("authorization", "Bearer #{token}")
        |> VerifyToken.call(opts ++ [module: ctx.impl, error_handler: ctx.error_handler])

      assert conn.status == 401
    end
  end
end