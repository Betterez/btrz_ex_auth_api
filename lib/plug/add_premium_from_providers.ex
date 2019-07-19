defmodule BtrzAuth.Plug.AddPremiumFromProviders do
  @moduledoc """

  Looks for the `provider_ids` in the query params and fetchs its premium keys using account data under `conn.private.account`
  saved by `BtrzAuth.Plug.VerifyApiKey` (the order of the plugs is very important!)

  This plug will look for `providerId` or `provider_id` or a list of comma separated ids in `providerIds` or
  `provider_ids`.

  This plug assumes that `BtrzAuth.Plug.VerifyProviders` already verified that the providers are valid for the account.
  If the passed provider/s have premium keys, these will be added to the ones of the `conn.private.account`.

  ### Example

  ```elixir
  plug BtrzAuth.Plug.AddPremiumFromProviders

  ```
  """
  import Plug.Conn

  require Logger

  def init(_params) do
  end

  def call(conn, _) do
    Logger.debug("accessing AddPremiumFromProviders plug..")

    conn
    |> get_provider_ids_from_query()
    |> add_premium_from_providers(conn)
  end

  defp get_provider_ids_from_query(conn) do
    conn = fetch_query_params(conn)

    (conn.query_params["providerIds"] || conn.query_params["provider_ids"] ||
       conn.query_params["providerId"] || conn.query_params["provider_id"] ||
       "")
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
  end

  defp add_premium_from_providers(provider_ids, %{private: %{account: account}} = conn) do
    premiums =
      provider_ids
      |> Enum.reduce(Map.get(account, "premium", []), fn provider_id, premium_list ->
        account
        |> Map.get("providers", %{})
        |> Map.get(provider_id, %{})
        |> Map.get("premium", [])
        |> Kernel.++(premium_list)
      end)
      |> Enum.uniq()

    put_in(conn.private.account["premium"], premiums)
  end

  defp add_premium_from_providers(_provider_ids, conn), do: conn
end
