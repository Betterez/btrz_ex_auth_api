if Code.ensure_loaded?(Plug) do
  defmodule BtrzAuth.Plug.VerifyApiKey do
    @moduledoc """

    Looks for and validates a token found in the `x-api-key` header using mongodb driver to verify the collection/property that matches the token.

    This, like all other Guardian plugs, requires a Guardian pipeline to be setup.
    It requires an implementation module, an error handler and a key.

    These can be set either:

    1. Upstream on the connection with `plug Guardian.Pipeline`
    2. Upstream on the connection with `Guardian.Pipeline.{put_module, put_error_handler, put_key}`
    3. Inline with an option of `:module`, `:error_handler`, `:key`

    If a token is found but is invalid, the error handler will be called with
    `auth_error(conn, {:api_key_not_found, reason}, opts)`

    Once a token has been found, it will be matched against the database using the configured collection and property,
    if not found, the error handler will be called with
    `auth_error(conn, {:account_not_found, reason}, opts)`

    Options:

    * `search_in` - atom. The places to look for the x-api-key (`:header`, `:query` or `:all`). Defaults to: `:all`
    * `allow_blank` - boolean. If set to true, will try to load a resource once the x-api-key is found, but will not fail if no resource is found. Defaults: false

    ### Example

    ```elixir

    # default search and verify in all (header and query string)
    plug BtrzAuth.Plug.VerifyApiKey
    # search only in header
    plug BtrzAuth.Plug.VerifyApiKey, search_in: :header

    ```
    """
    import Plug.Conn

    alias Guardian.Plug.Pipeline

    require Logger

    @token_config Application.get_env(:btrz_auth, :token)
    @db_config Application.get_env(:btrz_auth, :db)

    @spec init(Keyword.t()) :: Keyword.t()
    def init(opts), do: opts

    @spec call(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
    def call(conn, opts) do
      allow_blank = Keyword.get(opts, :allow_blank, false)
      search_in = Keyword.get(opts, :search_in, :all)

      case get_api_key(conn, search_in) do
        nil ->
          respond({{:error, :api_key_not_found}, allow_blank, conn, opts})

        api_key ->
          if Mix.env === :test do
            # only for test
            conn = put_private(conn, :auth_account, Keyword.get(@token_config, :test_resource, %{}))
            respond({{:ok, :api_key}, allow_blank, conn, opts})
          else
            {:ok, mongo_conn} =
              Mongo.start_link(database: @db_config[:database], seeds: @db_config[:uris])

            case Mongo.find_one(mongo_conn, @db_config[:collection_name], %{
                  @db_config[:property] => api_key
                }) do
              nil ->
                respond({{:error, :account_not_found}, allow_blank, conn, opts})

              result ->
                conn = put_private(conn, :auth_account, result)
                respond({{:ok, :api_key}, allow_blank, conn, opts})
            end
          end
      end
    end

    defp get_api_key(conn, :header), do: get_api_key_from_header(conn)
    defp get_api_key(conn, :query), do: get_api_key_from_query(conn)
    defp get_api_key(conn, _), do: get_api_key_from_header(conn) || get_api_key_from_query(conn)

    defp get_api_key_from_header(conn) do
      case get_req_header(conn, "x-api-key") do
        [] -> nil
        api_keys -> hd(api_keys)
      end
    end

    defp get_api_key_from_query(conn) do
      conn = fetch_query_params(conn)
      conn.query_params["x-api-key"]
    end

    defp respond({{:ok, _}, _allow_blank, conn, _opts}), do: conn
    defp respond({{:error, :account_not_found}, allow_blank = true, conn, opts}), do: conn

    defp respond({{:error, :account_not_found}, allow_blank = false, conn, opts}),
      do: respond_error(conn, :account_not_found, opts)

    defp respond({{:error, :api_key_not_found}, _allow_blank, conn, opts}),
      do: respond_error(conn, :api_key_not_found, opts)

    defp respond_error(conn, reason, opts) do
      conn
      |> Pipeline.fetch_error_handler!(opts)
      |> apply(:auth_error, [conn, {:unauthenticated, reason}, opts])
      |> halt()
    end
  end
end
