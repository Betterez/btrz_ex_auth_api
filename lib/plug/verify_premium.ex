if Code.ensure_loaded?(Plug) do
  defmodule BtrzAuth.Plug.VerifyPremium do
    @moduledoc """

    Looks for and validates that the passed `keys` features are present in the saved claims under `conn.private` using `BtrzAuth.Guardian.Plug.current_claims(conn)`.

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
    def call(%Plug.Conn{private: %{btrz_token_type: :internal}} = conn, opts), do: conn

    def call(conn, opts) do
      Logger.debug("accessing VerifyPremium plug with opts: #{inspect(opts)}..")

      case GPlug.current_claims(conn) do
        nil ->
          conn

        claims ->
          claims
          |> Map.get(:premium, [])
          |> validate_premium_keys(conn, opts)
      end
    end

    @doc false
    @spec validate_premium_keys(List.t(), Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
    defp validate_premium_keys(claims, conn, opts) do
      keys = opts[:keys]
      diff_length = difference(claims, keys) |> length()

      if length(claims) === diff_length + length(keys) do
        conn
      else
        respond_error(conn, :premium_not_verified, opts)
      end
    end

    @doc false
    defp difference(list1, list2) do
      list1 -- list2
    end

    @doc false
    # @spec response_error(Plug.Conn.t(), any, Keyword.t()) :: Plug.Conn.t()
    defp respond_error(conn, reason, opts) do
      conn
      |> Pipeline.fetch_error_handler!(opts)
      |> apply(:auth_error, [conn, {:unauthenticated, reason}, opts])
      |> halt()
    end
  end
end
