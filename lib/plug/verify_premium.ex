if Code.ensure_loaded?(Plug) do
  defmodule BtrzAuth.Plug.VerifyPremium do
    @moduledoc """

    Looks for and validates that the passed `keys` features are present in the account data under `conn.private.account["premium"]`
    saved by `BtrzAuth.Plug.VerifyApiKey` (the order of the plugs is very important!)

    This, like all other Guardian plugs, requires a Guardian pipeline to be setup.
    It requires an error handler as `error_handler`.

    These can be set either:

    1. Upstream on the connection with `plug Guardian.Pipeline`
    2. Upstream on the connection with `Guardian.Pipeline.{put_module, put_error_handler, put_key}`
    3. Inline with an option of `:module`, `:error_handler`, `:key`

    If the claims are not found, the pipeline will be halted and the error handler will be called with
    `auth_error(conn, {:premium_not_verified, reason}, opts)`

    Options:

    * `keys` - list of atom premium features to verify. Defaults to: `[]`

    ### Example

    ```elixir
    plug BtrzAuth.Plug.VerifyPremium, keys: [:special_content]

    ```
    """
    import Plug.Conn

    alias Guardian.Plug, as: GPlug
    alias GPlug.Pipeline

    require Logger

    @spec init(Keyword.t()) :: Keyword.t()
    def init(opts) do
      keys = Keyword.get(opts, :keys, [])
      Keyword.put(opts, :keys, keys)
    end

    @spec call(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
    def call(%Plug.Conn{private: %{btrz_token_type: :internal}} = conn, _opts), do: conn

    def call(conn, opts) do
      Logger.debug("accessing VerifyPremium plug with opts: #{inspect(opts)}..")

      with account <- Map.get(conn.private, :account),
        premium_keys <- get_premium_keys(account),
        true <- are_valid_premium_keys?(premium_keys, opts) do
          conn
        else
          _ ->
            conn
            |> Pipeline.fetch_error_handler!(opts)
            |> apply(:auth_error, [conn, {:unauthorized, :premium_not_verified}, opts])
            |> halt()
        end
    end

    defp get_premium_keys(%{"premium" => premium}) do
      premium |> Enum.map(fn x -> String.to_atom(x) end)
    end
    defp get_premium_keys(_), do: []

    @doc false
    @spec are_valid_premium_keys?(List.t(), Keyword.t()) :: Boolean.t()
    defp are_valid_premium_keys?(premium, opts) do
      keys = opts[:keys]
      diff = premium -- keys
      length(premium) === length(diff) + length(keys)
    end
  end
end
