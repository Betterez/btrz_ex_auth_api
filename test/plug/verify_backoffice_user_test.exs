defmodule BtrzAuth.Plug.VerifyBackofficeUserTest do
  @moduledoc false

  use Plug.Test
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  alias BtrzAuth.Plug.{VerifyBackofficeUser, VerifyToken}

  @user_id "000000000000000000000001"
  @customer_id "000000000000000000000002"

  defp refused?(conn) do
    conn.halted and conn.status == 401 and
      Jason.decode!(conn.resp_body) == %{
        "error" => "unauthorized",
        "reason" => "backoffice_user_required"
      }
  end

  describe "init/1" do
    test "lets internal tokens through by default" do
      assert VerifyBackofficeUser.init([])[:allow_internal] == true
      assert VerifyBackofficeUser.init()[:allow_internal] == true
    end

    test "keeps allow_internal when given" do
      assert VerifyBackofficeUser.init(allow_internal: false)[:allow_internal] == false
    end

    test "allows the betterez-app audience by default" do
      assert VerifyBackofficeUser.init([])[:audiences] == [:BETTEREZ_APP]
    end

    test "keeps the audiences when given" do
      opts = VerifyBackofficeUser.init(audiences: [:BETTEREZ_APP, :MOBILE_SCANNER])
      assert opts[:audiences] == [:BETTEREZ_APP, :MOBILE_SCANNER]
    end

    test "raises on an audience it doesn't know" do
      assert_raise ArgumentError, fn -> VerifyBackofficeUser.init(audiences: [:SOMETHING_NEW]) end
    end

    test "raises when the customer audience is allowed" do
      assert_raise ArgumentError, fn -> VerifyBackofficeUser.init(audiences: [:CUSTOMER]) end

      assert_raise ArgumentError, fn ->
        VerifyBackofficeUser.init(audiences: [:BETTEREZ_APP, :CUSTOMER])
      end
    end

    test "raises on an empty list of audiences" do
      assert_raise ArgumentError, fn -> VerifyBackofficeUser.init(audiences: []) end
    end
  end

  describe "call/2 with the private data VerifyToken stores" do
    defp call(token_type, private, claims, opts \\ []) do
      conn =
        :post
        |> conn("/")
        |> put_private(:btrz_token_type, token_type)

      private
      |> Enum.reduce(conn, fn {key, value}, conn -> put_private(conn, key, value) end)
      |> Guardian.Plug.put_current_claims(claims)
      |> VerifyBackofficeUser.call(VerifyBackofficeUser.init(opts))
    end

    test "lets a back-office user token with an id through" do
      conn =
        call(:user, %{user_id: @user_id, user_aud: "betterez-app"}, %{
          "id" => @user_id,
          "aud" => "betterez-app"
        })

      refute conn.halted
      assert conn.private.user_id == @user_id
    end

    test "takes the user from _id when the token has no id, as long user tokens" do
      conn =
        call(:user, %{user_id: nil, user_aud: "betterez-app"}, %{
          "_id" => @user_id,
          "aud" => "betterez-app"
        })

      refute conn.halted
      assert conn.private.user_id == @user_id
    end

    test "lets another audience through when it is allowed" do
      conn =
        call(
          :user,
          %{user_id: @user_id, user_aud: "btrz-mobile-scanner"},
          %{"id" => @user_id, "aud" => "btrz-mobile-scanner"},
          audiences: [:BETTEREZ_APP, :MOBILE_SCANNER]
        )

      refute conn.halted
    end

    test "refuses a known audience that is not allowed" do
      capture_log(fn ->
        assert refused?(
                 call(:user, %{user_id: @user_id, user_aud: "btrz-mobile-scanner"}, %{
                   "id" => @user_id,
                   "aud" => "btrz-mobile-scanner"
                 })
               )
      end)
    end

    test "refuses an audience it doesn't know, such as an application's name" do
      capture_log(fn ->
        assert refused?(
                 call(:user, %{user_id: nil, user_aud: "my-integration"}, %{
                   "_id" => @user_id,
                   "aud" => "my-integration"
                 })
               )
      end)
    end

    test "refuses a token without an audience" do
      capture_log(fn ->
        assert refused?(call(:user, %{user_id: @user_id, user_aud: nil}, %{"id" => @user_id}))
      end)
    end

    test "lets the test token through when the test sets an allowed audience and a user id" do
      conn = call(:test, %{user_id: @user_id, user_aud: "betterez-app"}, %{})

      refute conn.halted
      assert conn.private.user_id == @user_id
    end

    test "lets an internal token through without a user" do
      conn = call(:internal, %{user_id: nil, user_aud: nil}, %{})

      refute conn.halted
      assert conn.private.user_id == nil
    end

    test "refuses an internal token with allow_internal: false" do
      capture_log(fn ->
        assert refused?(call(:internal, %{user_id: nil}, %{}, allow_internal: false))
      end)
    end

    test "refuses a customer token" do
      capture_log(fn ->
        assert refused?(
                 call(:user, %{user_id: nil, user_aud: "customer"}, %{
                   "_id" => @customer_id,
                   "aud" => "customer",
                   "customerNumber" => "123-456-789"
                 })
               )
      end)
    end

    test "refuses a customer token even when it has an id" do
      capture_log(fn ->
        assert refused?(
                 call(:user, %{user_id: @customer_id, user_aud: "customer"}, %{
                   "id" => @customer_id,
                   "aud" => "customer"
                 })
               )
      end)
    end

    test "refuses a user token without a user id" do
      capture_log(fn ->
        assert refused?(
                 call(:user, %{user_id: nil, user_aud: "betterez-app"}, %{"aud" => "betterez-app"})
               )
      end)
    end

    test "refuses a user token whose user id is empty" do
      capture_log(fn ->
        assert refused?(
                 call(:user, %{user_id: "", user_aud: "betterez-app"}, %{
                   "id" => "",
                   "aud" => "betterez-app"
                 })
               )
      end)
    end

    test "refuses a user token whose user id is not a string" do
      capture_log(fn ->
        assert refused?(
                 call(:user, %{user_id: nil, user_aud: "betterez-app"}, %{
                   "_id" => %{"$oid" => @user_id},
                   "aud" => "betterez-app"
                 })
               )
      end)
    end

    test "refuses the test token when the test sets no user id" do
      capture_log(fn -> assert refused?(call(:test, %{user_aud: "betterez-app"}, %{})) end)
    end

    test "refuses the test token when the test sets no audience" do
      capture_log(fn -> assert refused?(call(:test, %{user_id: @user_id}, %{})) end)
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

    # Signed with the account's application private key, as btrz-api-accounts signs user, customer and
    # application tokens.
    defp user_token(ctx, resource, claims) do
      {:ok, token, _claims} =
        BtrzAuth.GuardianUser.encode_and_sign(resource, claims,
          secret: ctx.token_config[:test_resource]["private_key"]
        )

      token
    end

    defp internal_token(ctx) do
      {:ok, token, _claims} = BtrzAuth.internal_auth_token(ctx.token_config)
      token
    end

    defp verify(ctx, token, opts \\ []) do
      ctx.conn
      |> put_req_header("authorization", "Bearer #{token}")
      |> VerifyToken.call(VerifyToken.init())
      |> VerifyBackofficeUser.call(VerifyBackofficeUser.init(opts))
    end

    test "lets a back-office user's short token through", ctx do
      token = user_token(ctx, %{"id" => @user_id}, %{"id" => @user_id, "aud" => "betterez-app"})

      conn = verify(ctx, token)

      refute conn.halted
      assert conn.private.btrz_token_type == :user
      assert conn.private.user_id == @user_id
    end

    test "lets a back-office user's long token through, with the user from _id", ctx do
      token = user_token(ctx, %{"_id" => @user_id}, %{"_id" => @user_id, "aud" => "betterez-app"})

      conn = verify(ctx, token)

      refute conn.halted
      assert conn.private.user_id == @user_id
    end

    test "refuses an application token, whose audience is the application's name", ctx do
      token =
        user_token(ctx, %{"_id" => @user_id}, %{"_id" => @user_id, "aud" => "my-integration"})

      capture_log(fn ->
        conn = verify(ctx, token)
        assert conn.private.btrz_token_type == :user
        assert refused?(conn)
      end)
    end

    test "refuses a customer token", ctx do
      token =
        user_token(ctx, %{"_id" => @customer_id}, %{
          "_id" => @customer_id,
          "customerNumber" => "123-456-789",
          "aud" => "customer"
        })

      capture_log(fn ->
        conn = verify(ctx, token)
        assert conn.private.btrz_token_type == :user
        assert refused?(conn)
      end)
    end

    test "lets an internal token through", ctx do
      conn = verify(ctx, internal_token(ctx))

      refute conn.halted
      assert conn.private.btrz_token_type == :internal
    end

    test "refuses an internal token with allow_internal: false", ctx do
      capture_log(fn ->
        conn = verify(ctx, internal_token(ctx), allow_internal: false)
        assert conn.private.btrz_token_type == :internal
        assert refused?(conn)
      end)
    end
  end
end
