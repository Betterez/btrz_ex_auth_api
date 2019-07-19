if Code.ensure_loaded?(Plug) do
  defmodule BtrzAuth.Plug.VerifyPremium do
    @moduledoc """

    Looks for and validates that the passed `keys` features are present in the account data under `conn.private.account["premium"]`
    saved by `BtrzAuth.Plug.VerifyApiKey` (the order of the plugs is very important!)

    If the premium keys are not found under `conn.private.account`, the pipeline will be halted and the `conn.resp_body` with:

    ```elixir
    %{
      "error" => "unauthorized",
      "reason" => "premium_not_verified"
    }
    ```

    Options:

    * `keys` - list of atom premium features to verify. Defaults to: `[]`

    ### Example

    ```elixir
    plug BtrzAuth.Plug.VerifyPremium, keys: [:special_content]

    ```
    """
    import Plug.Conn

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
          |> BtrzAuth.ErrorHandler.auth_error({:unauthorized, :premium_not_verified})
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
