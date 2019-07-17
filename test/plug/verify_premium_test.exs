defmodule BtrzAuth.Plug.VerifyPremiumTest do
  @moduledoc false

  use Plug.Test
  use ExUnit.Case, async: true

  alias BtrzAuth.Plug.VerifyPremium

  defmodule ErrorHandler do
    @moduledoc false

    import Plug.Conn

    def auth_error(conn, {type, reason}, _opts) do
      body = inspect({type, reason})
      send_resp(conn, 401, body)
    end
  end

  describe "init/1" do
    test "will use the config keys" do
      opts = [keys: "value"]
      result_opts = VerifyPremium.init(opts)
      assert result_opts == opts
    end

    test "will use [] default for keys" do
      opts = []
      result_opts = VerifyPremium.init(opts)
      assert result_opts[:keys] == []
    end
  end

  describe "call/2" do
    setup do
      error_handler = __MODULE__.ErrorHandler

      conn =
        :get
        |> conn("/")
        |> put_private(:btrz_token_type, :user)

      {:ok, %{conn: conn, error_handler: error_handler}}
    end

    test "will pass validating the :great_feature premium key", ctx do
      keys = [keys: [:great_feature]]
      opts = VerifyPremium.init(keys)

      conn =
        ctx.conn
        |> put_private(:account, %{"premium" => ["great_feature"]})
        |> VerifyPremium.call(opts ++ [error_handler: ctx.error_handler])

      refute conn.status == 401
    end

    test "will pass validating the :great_feature premium key between more than one", ctx do
      keys = [keys: [:great_feature]]
      opts = VerifyPremium.init(keys)

      conn =
        ctx.conn
        |> put_private(:account, %{"premium" => ["a", "great_feature", "b", "c"]})
        |> VerifyPremium.call(opts ++ [error_handler: ctx.error_handler])

      refute conn.status == 401
    end

    test "will pass if no keys passed no matter if the account has premium keys or not", ctx do
      opts = VerifyPremium.init([])

      conn =
        ctx.conn
        |> put_private(:account, %{})
        |> VerifyPremium.call(opts ++ [error_handler: ctx.error_handler])

      refute conn.status == 401
    end

    test "will return 401 if premium key not found because the account has no premium property",
         ctx do
      keys = [keys: [:z]]
      opts = VerifyPremium.init(keys)

      conn =
        ctx.conn
        |> put_private(:account, %{})
        |> VerifyPremium.call(opts ++ [error_handler: ctx.error_handler])

      assert conn.status == 401
      assert conn.resp_body == "{:unauthorized, :premium_not_verified}"
    end

    test "will return 401 if premium key not found", ctx do
      keys = [keys: [:z]]
      opts = VerifyPremium.init(keys)

      conn =
        ctx.conn
        |> put_private(:account, %{"premium" => ["a", "great_feature", "b", "c"]})
        |> VerifyPremium.call(opts ++ [error_handler: ctx.error_handler])

      assert conn.status == 401
      assert conn.resp_body == "{:unauthorized, :premium_not_verified}"
    end

    test "will return 401 if is valid one of two keys", ctx do
      keys = [keys: [:great_feature, :admin]]
      opts = VerifyPremium.init(keys)

      conn =
        ctx.conn
        |> put_private(:account, %{"premium" => ["a", "great_feature", "b", "c"]})
        |> VerifyPremium.call(opts ++ [error_handler: ctx.error_handler])

      assert conn.status == 401
    end

    test "with btrz_token_type :internal always will pass", ctx do
      keys = [keys: [:great_feature, :admin]]
      opts = VerifyPremium.init(keys)

      conn =
        ctx.conn
        |> put_private(:account, %{"premium" => ["a"]})
        |> put_private(:btrz_token_type, :internal)
        |> VerifyPremium.call(opts ++ [error_handler: ctx.error_handler])

      refute conn.status == 401
    end
  end
end
