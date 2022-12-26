defmodule BtrzAuth.Plug.VerifyProviders do
  @moduledoc """

  Looks for and validates if there are `provider_ids` in the query params and if they are valids with the account data under `conn.private.account`
  saved by `BtrzAuth.Plug.VerifyApiKey` (the order of the plugs is very important!)

  This plug will look for `providerId` or `provider_id` or a list of comma separated ids in `providerIds` or
  `provider_ids`.

  This, like all other Guardian plugs, requires a Guardian pipeline to be setup.
  It requires an error handler as `error_handler`.

  These can be set either:

  1. Upstream on the connection with `plug Guardian.Pipeline`
  2. Upstream on the connection with `Guardian.Pipeline.{put_module, put_error_handler, put_key}`
  3. Inline with an option of `:module`, `:error_handler`, `:key`

  If any provider is invalid, the pipeline will be halted and an error with status 400 will be set in the `conn.resp_body` like this:

  ```elixir
  %{
    "status" => 400,
    "code" => "INVALID_PROVIDER_ID",
    "message" => "Error getting provider"
  }
  ```

  ### Example

  ```elixir
  plug BtrzAuth.Plug.VerifyProviders

  ```
  """
  import Plug.Conn

  alias Guardian.Plug.Pipeline

  require Logger

  @spec init(Keyword.t()) :: Keyword.t()
  def init(opts), do: opts

  @spec call(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
  def call(conn, opts) do
    Logger.debug("accessing VerifyProviders plug..")

    conn
    |> get_provider_ids_from_query()
    |> validate_provider_ids(conn, Pipeline.fetch_error_handler!(conn, opts))
  end

  defp get_provider_ids_from_query(conn) do
    conn = fetch_query_params(conn)

    (conn.query_params["providerIds"] || conn.query_params["provider_ids"] ||
       conn.query_params["providerId"] || conn.query_params["provider_id"] || "")
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
  end

  defp is_a_valid_provider?(account, provider_id) do
    nil !=
      account
      |> Map.get("providers", %{})
      |> Map.get(provider_id)
  end

  defp validate_provider_ids([], conn, _error_handler), do: conn

  defp validate_provider_ids(provider_ids, %{private: %{account: account}} = conn, error_handler)
       when is_map(account) do
    if Enum.all?(provider_ids, &is_a_valid_provider?(account, &1)) do
      conn
    else
      respond_error(conn, error_handler)
    end
  end

  defp validate_provider_ids(_provider_id, conn, error_handler),
    do: respond_error(conn, error_handler)

  defp respond_error(conn, error_handler) do
    error_handler
    |> apply(:validation_error, [conn])
    |> halt()
  end
end
