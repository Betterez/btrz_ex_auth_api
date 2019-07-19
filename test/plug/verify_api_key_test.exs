defmodule BtrzAuth.Plug.VerifyApiKeyTest do
  @moduledoc false

  use Plug.Test
  use ExUnit.Case, async: true

  alias BtrzAuth.Plug.VerifyApiKey

  @test_api_key "test-token"
  @test_resource Application.get_env(:btrz_ex_auth_api, :token)[:test_resource]

  describe "init/1" do
    test "will use the config keys" do
      opts = [any: "value"]
      result_opts = VerifyApiKey.init(opts)
      assert result_opts == opts
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

      assert conn.private[:account]["private_key"] == @test_resource["private_key"]
    end

    test "using the test x-api-key for :test env" do
      conn =
        :get
        |> conn("/")
        |> put_req_header("x-api-key", @test_api_key)
        |> VerifyApiKey.call([])

      refute conn.status == 401

      assert conn.private[:account]["private_key"] == @test_resource["private_key"]
    end

    test "merge the conn.private.account with the test_resource one" do
      conn =
        :get
        |> conn("/")
        |> put_req_header("x-api-key", @test_api_key)
        |> put_private(:account, %{"my_prop" => "oh!", "private_key" => "overriden"})
        |> VerifyApiKey.call([])

      refute conn.status == 401

      assert conn.private[:account]["private_key"] == "overriden"
      assert conn.private[:account]["my_prop"] == "oh!"
    end

    test "will use the x-api-key header sent with search_in :all" do
      conn =
        :get
        |> conn("/")
        |> put_req_header("x-api-key", "fa413eed-b4ef-4b4c-859b-693aaa31376d")
        |> VerifyApiKey.call(search_in: :all)

      refute conn.status == 401

      assert conn.private[:account]["private_key"] == @test_resource["private_key"]
    end

    test "will find the x-api-key header but not the resource -> with allow_blank" do
      conn =
        :get
        |> conn("/")
        |> put_req_header("x-api-key", "x-x-x-x-x-x-x-x-x-x-x-")
        |> VerifyApiKey.call(allow_blank: true)

      refute conn.status == 401

      assert conn.private[:account]["private_key"] == @test_resource["private_key"]
    end

    test "will find the x-api-key query string but not the resource -> with allow_blank" do
      conn =
        :get
        |> conn("/?x-api-key=x-x-x-x-x-x-x-x-x-")
        |> VerifyApiKey.call(allow_blank: true)

      refute conn.status == 401

      assert conn.private[:account]["private_key"] == @test_resource["private_key"]
    end

    test "will use the x-api-key query string sent" do
      conn =
        :get
        |> conn("/?x-api-key=fa413eed-b4ef-4b4c-859b-693aaa31376d")
        |> VerifyApiKey.call([])

      refute conn.status == 401

      assert conn.private[:account]["private_key"] == @test_resource["private_key"]
    end

    test "will use the x-api-key query string sent if search_in :all" do
      conn =
        :get
        |> conn("/?x-api-key=fa413eed-b4ef-4b4c-859b-693aaa31376d")
        |> VerifyApiKey.call(search_in: :all)

      refute conn.status == 401

      assert conn.private[:account]["private_key"] == @test_resource["private_key"]
    end

    test "will search only for x-api-key in header" do
      conn =
        :get
        |> conn("/?x-api-key=fa413eed-b4ef-4b4c-859b-693aaa31376d")
        |> VerifyApiKey.call(search_in: :header, error_handler: BtrzAuth.ErrorHandler)

      assert conn.status == 401

      assert Jason.decode!(conn.resp_body) == %{
               "error" => "unauthenticated",
               "reason" => "api_key_not_found"
             }
    end

    test "will search only for x-api-key in query string" do
      conn =
        :get
        |> conn("/")
        |> put_req_header("x-api-key", "fa413eed-b4ef-4b4c-859b-693aaa31376d")
        |> VerifyApiKey.call(search_in: :query, error_handler: BtrzAuth.ErrorHandler)

      assert conn.status == 401

      assert Jason.decode!(conn.resp_body) == %{
               "error" => "unauthenticated",
               "reason" => "api_key_not_found"
             }
    end

    test "401 if x-api-key was not passed" do
      conn =
        :get
        |> conn("/")
        |> VerifyApiKey.call(error_handler: BtrzAuth.ErrorHandler)

      assert conn.status == 401

      assert Jason.decode!(conn.resp_body) == %{
               "error" => "unauthenticated",
               "reason" => "api_key_not_found"
             }
    end
  end
end
