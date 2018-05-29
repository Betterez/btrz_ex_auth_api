defmodule BtrzAuth.Plug.VerifyApiKeyTest do
  @moduledoc false

  use Plug.Test

  alias BtrzAuth.Plug.VerifyApiKey
  alias Guardian.Plug, as: GPlug
  alias GPlug.Pipeline

  use ExUnit.Case, async: true

  @test_api_key "test-token"

  defmodule Handler do
    @moduledoc false

    import Plug.Conn

    def auth_error(conn, {type, reason}, _opts) do
      body = inspect({type, reason})
      send_resp(conn, 401, body)
    end
  end

  describe "call/2" do
    test "will use the x-api-key header sent" do
      conn =
        :get
        |> conn("/")
        |> put_req_header("x-api-key", "fa413eed-b4ef-4b4c-859b-693aaa31376d")
        |> VerifyApiKey.call([])

      refute conn.status == 401
      assert conn.private[:application] == Application.get_env(:btrz_auth, :token)[:test_resource]
    end

    test "using the test x-api-key for :test env" do
      conn =
        :get
        |> conn("/")
        |> put_req_header("x-api-key", @test_api_key)
        |> VerifyApiKey.call([])

      refute conn.status == 401
      assert conn.private[:application] == Application.get_env(:btrz_auth, :token)[:test_resource]
    end

    test "will use the x-api-key header sent with search_in :all" do
      conn =
        :get
        |> conn("/")
        |> put_req_header("x-api-key", "fa413eed-b4ef-4b4c-859b-693aaa31376d")
        |> VerifyApiKey.call(search_in: :all)

      refute conn.status == 401
      assert conn.private[:application] == Application.get_env(:btrz_auth, :token)[:test_resource]
    end

    test "will find the x-api-key header but not the resource -> with allow_blank" do
      conn =
        :get
        |> conn("/")
        |> put_req_header("x-api-key", "x-x-x-x-x-x-x-x-x-x-x-")
        |> VerifyApiKey.call(allow_blank: true)

      refute conn.status == 401
      assert conn.private[:application] == Application.get_env(:btrz_auth, :token)[:test_resource]
    end

    test "will find the x-api-key query string but not the resource -> with allow_blank" do
      conn =
        :get
        |> conn("/?x-api-key=x-x-x-x-x-x-x-x-x-")
        |> VerifyApiKey.call(allow_blank: true)

      refute conn.status == 401
      assert conn.private[:application] == Application.get_env(:btrz_auth, :token)[:test_resource]
    end

    test "will use the x-api-key query string sent" do
      conn =
        :get
        |> conn("/?x-api-key=fa413eed-b4ef-4b4c-859b-693aaa31376d")
        |> VerifyApiKey.call([])

      refute conn.status == 401
      assert conn.private[:application] == Application.get_env(:btrz_auth, :token)[:test_resource]
    end

    test "will use the x-api-key query string sent if search_in :all" do
      conn =
        :get
        |> conn("/?x-api-key=fa413eed-b4ef-4b4c-859b-693aaa31376d")
        |> VerifyApiKey.call(search_in: :all)

      refute conn.status == 401
      assert conn.private[:application] == Application.get_env(:btrz_auth, :token)[:test_resource]
    end

    test "will search only for x-api-key in header" do
      conn =
        :get
        |> conn("/?x-api-key=fa413eed-b4ef-4b4c-859b-693aaa31376d")
        |> VerifyApiKey.call(search_in: :header, error_handler: __MODULE__.Handler)

      assert conn.status == 401
      assert conn.resp_body == "{:unauthenticated, :api_key_not_found}"
    end

    test "will search only for x-api-key in query string" do
      conn =
        :get
        |> conn("/")
        |> put_req_header("x-api-key", "fa413eed-b4ef-4b4c-859b-693aaa31376d")
        |> VerifyApiKey.call(search_in: :query, error_handler: __MODULE__.Handler)

      assert conn.status == 401
      assert conn.resp_body == "{:unauthenticated, :api_key_not_found}"
    end

    test "401 if x-api-key was not passed" do
      conn =
        :get
        |> conn("/")
        |> VerifyApiKey.call(error_handler: __MODULE__.Handler)

      assert conn.status == 401
      assert conn.resp_body == "{:unauthenticated, :api_key_not_found}"
    end
  end
end
