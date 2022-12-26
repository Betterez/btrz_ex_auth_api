defmodule BtrzAuth.Plug.VerifyAudiencesTest do
  @moduledoc false

  use Plug.Test
  use ExUnit.Case, async: true

  alias BtrzAuth.Plug.VerifyAudiences

  describe "init/1" do
    test "will fail if audiences are empty" do
      opts = [audiences: []]
      result_opts = VerifyAudiences.init(opts)
      assert result_opts == {:error, "invalid_audiences"}
    end

    test "will fail if at least one audiences is invalid" do
      opts = [audiences: [:CUSTOMER, :INVALID]]
      result_opts = VerifyAudiences.init(opts)
      assert result_opts == {:error, "invalid_audiences"}
    end

    test "will validate and put the audiences in the enum when are valid" do
      opts = [audiences: [:CUSTOMER, :BETTEREZ_APP]]
      result_opts = VerifyAudiences.init(opts)
      assert result_opts == opts
    end
  end

  describe "call/2" do
    setup do
      conn =
        :get
        |> conn("/")
        |> put_private(:btrz_token_type, :user)

      {:ok, %{conn: conn}}
    end

    test "will not pass if the token was created with an valid audience but not the audience defined in the plug config",
         ctx do
      audiences = [audiences: [:BETTEREZ_APP]]
      opts = VerifyAudiences.init(audiences)

      conn =
        ctx.conn
        |> put_private(:user_aud, "btrz-mobile-scanner")
        |> VerifyAudiences.call(opts)

      assert conn.status == 401
    end

    test "will not pass if the token was created with an invalid audience", ctx do
      audiences = [audiences: [:BETTEREZ_APP]]
      opts = VerifyAudiences.init(audiences)

      conn =
        ctx.conn
        |> put_private(:user_aud, "btrz-invalid-audience")
        |> VerifyAudiences.call(opts)

      assert conn.status == 401
    end

    test "will pass if the token was created for at least one audience", ctx do
      audiences = [audiences: [:BETTEREZ_APP, :CUSTOMER]]
      opts = VerifyAudiences.init(audiences)

      conn =
        ctx.conn
        |> put_private(:user_aud, "betterez-app")
        |> VerifyAudiences.call(opts)

      refute conn.status == 401
    end
  end
end
