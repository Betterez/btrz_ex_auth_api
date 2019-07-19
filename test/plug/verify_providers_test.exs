defmodule BtrzAuth.Plug.VerifyProvidersTest do
  @moduledoc false

  use Plug.Test
  use ExUnit.Case, async: true

  alias BtrzAuth.Plug.VerifyProviders

  describe "call/2" do
    setup do
      conn =
        :get
        |> conn("/")
        |> put_private(:account, %{"providers" => %{}})

      {:ok, %{conn: conn}}
    end

    test "without passing a provider_id it should pass", %{conn: conn} do
      conn =
        conn
        |> VerifyProviders.call(error_handler: BtrzAuth.ErrorHandler)

      refute conn.status == 400
    end

    test "passing an invalid providerId in the querystring will return 400", %{conn: _conn} do
      conn =
        :get
        |> conn("/?providerId=123")
        |> VerifyProviders.call(error_handler: BtrzAuth.ErrorHandler)

      assert conn.status == 400
      body = Jason.decode!(conn.resp_body)
      assert body["code"] == "INVALID_PROVIDER_ID"
      assert body["message"] == "Error getting provider"
    end

    test "passing an invalid providerId in the querystring list will return 400", %{conn: _conn} do
      a_provider_id = "123"

      providers = %{
        "bar" => %{},
        a_provider_id => %{}
      }

      conn =
        :get
        |> conn("/?providerIds=111, #{a_provider_id},9999999")
        |> put_private(:account, %{"providers" => providers})
        |> VerifyProviders.call(error_handler: BtrzAuth.ErrorHandler)

      assert conn.status == 400
      body = Jason.decode!(conn.resp_body)
      assert body["code"] == "INVALID_PROVIDER_ID"
      assert body["message"] == "Error getting provider"
    end

    test "passing a valid providerId in the querystring will pass", %{conn: _conn} do
      a_provider_id = "123"

      providers = %{
        "bar" => %{},
        a_provider_id => %{}
      }

      conn =
        :get
        |> conn("/?providerId=#{a_provider_id}")
        |> put_private(:account, %{"providers" => providers})
        |> VerifyProviders.call(error_handler: BtrzAuth.ErrorHandler)

      refute conn.status == 400
    end

    test "passing a valid providerIds in the querystring will pass", %{conn: _conn} do
      a_provider_id = "123"

      providers = %{
        "bar" => %{},
        a_provider_id => %{}
      }

      conn =
        :get
        |> conn("/?providerIds=#{a_provider_id}")
        |> put_private(:account, %{"providers" => providers})
        |> VerifyProviders.call(error_handler: BtrzAuth.ErrorHandler)

      refute conn.status == 400
    end

    test "passing an invalid provider_id in the querystring will return 400", %{conn: _conn} do
      conn =
        :get
        |> conn("/?provider_id=123")
        |> VerifyProviders.call(error_handler: BtrzAuth.ErrorHandler)

      assert conn.status == 400
      body = Jason.decode!(conn.resp_body)
      assert body["code"] == "INVALID_PROVIDER_ID"
      assert body["message"] == "Error getting provider"
    end

    test "passing an invalid provider_id in the querystring list will return 400", %{conn: _conn} do
      a_provider_id = "123"

      providers = %{
        "bar" => %{},
        a_provider_id => %{}
      }

      conn =
        :get
        |> conn("/?provider_ids=111, #{a_provider_id},9999999")
        |> put_private(:account, %{"providers" => providers})
        |> VerifyProviders.call(error_handler: BtrzAuth.ErrorHandler)

      assert conn.status == 400
      body = Jason.decode!(conn.resp_body)
      assert body["code"] == "INVALID_PROVIDER_ID"
      assert body["message"] == "Error getting provider"
    end

    test "passing a valid provider_id in the querystring will pass", %{conn: _conn} do
      a_provider_id = "123"

      providers = %{
        "bar" => %{},
        a_provider_id => %{}
      }

      conn =
        :get
        |> conn("/?provider_id=#{a_provider_id}")
        |> put_private(:account, %{"providers" => providers})
        |> VerifyProviders.call(error_handler: BtrzAuth.ErrorHandler)

      refute conn.status == 400
    end

    test "passing a list of valid provider_ids in the querystring will pass", %{conn: _conn} do
      providers = %{
        "bar" => %{},
        "foo" => %{}
      }

      conn =
        :get
        |> conn("/?provider_ids=foo,bar")
        |> put_private(:account, %{"providers" => providers})
        |> VerifyProviders.call(error_handler: BtrzAuth.ErrorHandler)

      refute conn.status == 400
    end
  end
end
