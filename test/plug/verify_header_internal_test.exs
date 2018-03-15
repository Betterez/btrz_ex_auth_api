defmodule BtrzAuth.Plug.VerifyHeaderInternalTest do
  @moduledoc false

  use Plug.Test

  alias BtrzAuth.Plug.VerifyHeaderInternal

  use ExUnit.Case, async: true

  defmodule Handler do
    @moduledoc false

    import Plug.Conn

    def auth_error(conn, {type, reason}, _opts) do
      body = inspect({type, reason})
      send_resp(conn, 401, body)
    end
  end

  defmodule Impl do
    @moduledoc false

    use Guardian,
      otp_app: :guardian

    def subject_for_token(%{id: id}, _claims), do: {:ok, id}
    def subject_for_token(%{"id" => id}, _claims), do: {:ok, id}

    def resource_from_claims(%{"sub" => id}), do: {:ok, %{id: id}}
  end

  @resource %{id: "bobby"}

  setup do
    impl = __MODULE__.Impl
    handler = __MODULE__.Handler
    secret = Application.get_env(:btrz_auth, :token)[:main_secret]
    {:ok, token, claims} = __MODULE__.Impl.encode_and_sign(@resource, %{}, [secret: secret])
    {:ok, %{claims: claims, conn: conn(:get, "/"), token: token, impl: impl, handler: handler}}
  end

  describe "init/1" do
    test "will use the config keys and default realm" do
      opts = VerifyHeaderInternal.init()
      assert opts[:main_secret] == Application.get_env(:btrz_auth, :token)[:main_secret]
      assert opts[:secondary_secret] == Application.get_env(:btrz_auth, :token)[:secondary_secret]
      assert opts[:realm_reg] == ~r/Bearer:? +(.*)$/i
    end

    test "will use the config keys and realm" do
      opts = VerifyHeaderInternal.init([realm: "test"])
      assert opts[:main_secret] == Application.get_env(:btrz_auth, :token)[:main_secret]
      assert opts[:secondary_secret] == Application.get_env(:btrz_auth, :token)[:secondary_secret]
      assert opts[:realm_reg] == ~r/test:? +(.*)$/i
    end
  end

  describe "call/2" do
    test "will use the main key and pass", ctx do
      opts = VerifyHeaderInternal.init()
      conn =
        :get
        |> conn("/")
        |> put_req_header("authorization", ctx.token)
        |> VerifyHeaderInternal.call(opts ++ [module: ctx.impl, error_handler: ctx.handler])

      refute conn.status == 401
    end
  end
end
