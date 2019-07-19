defmodule BtrzAuth.Plug.AddPremiumFromProvidersTest do
  @moduledoc false

  use Plug.Test
  use ExUnit.Case, async: true

  alias BtrzAuth.Plug.AddPremiumFromProviders

  describe "call/2" do
    setup do
      conn =
        :get
        |> conn("/")
        |> put_private(:account, %{"providers" => %{}, "premium" => []})

      {:ok, %{conn: conn}}
    end

    test "passing a providerId will add the premium keys of the provider", %{conn: _conn} do
      a_provider_id = "123"

      providers = %{
        "bar" => %{},
        a_provider_id => %{
          "premium" => ["a", "b"]
        }
      }

      conn =
        :get
        |> conn("/?providerId=#{a_provider_id}")
        |> put_private(:account, %{"providers" => providers, "premium" => ["b", "c"]})
        |> AddPremiumFromProviders.call([])

      refute conn.status == 400
      assert conn.private.account["premium"] == ["a", "b", "c"]
    end

    test "passing providerIds will add the premium keys of the providers", %{conn: _conn} do
      a_provider_id = "123"

      providers = %{
        "bar" => %{},
        a_provider_id => %{
          "premium" => ["a", "b"]
        }
      }

      conn =
        :get
        |> conn("/?providerIds=#{a_provider_id}")
        |> put_private(:account, %{"providers" => providers, "premium" => ["b", "c"]})
        |> AddPremiumFromProviders.call([])

      refute conn.status == 400
      assert conn.private.account["premium"] == ["a", "b", "c"]
    end

    test "passing a provider_id will add the premium keys of the provider", %{conn: _conn} do
      a_provider_id = "123"

      providers = %{
        "bar" => %{},
        a_provider_id => %{
          "premium" => ["a", "b"]
        }
      }

      conn =
        :get
        |> conn("/?provider_id=#{a_provider_id}")
        |> put_private(:account, %{"providers" => providers, "premium" => ["b", "c"]})
        |> AddPremiumFromProviders.call([])

      refute conn.status == 400
      assert conn.private.account["premium"] == ["a", "b", "c"]
    end

    test "passing provider_ids will add the premium keys of the providers", %{conn: _conn} do
      providers = %{
        "bar" => %{
          "premium" => ["z"]
        },
        "foo" => %{
          "premium" => ["a", "b"]
        }
      }

      conn =
        :get
        |> conn("/?provider_ids=foo,bar")
        |> put_private(:account, %{"providers" => providers, "premium" => ["b", "c"]})
        |> AddPremiumFromProviders.call([])

      refute conn.status == 400
      assert conn.private.account["premium"] == ["z", "a", "b", "c"]
    end
  end
end
