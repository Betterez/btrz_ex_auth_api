if Code.ensure_loaded?(Plug) do
  defmodule BtrzAuth.Plug.VerifyToken do
    @moduledoc """

    It depends on `BtrzAuth.Plug.VerifyApiKey`, looks for a token in the `Authorization` header and verify it using first the account's private key, if not valid, then main and secondary secrets provided by your app for internal token cases.

    In the case where:

    a. The session is not loaded
    b. A token is already found for `:key`

    This plug will not do anything.

    This, like all other Guardian plugs, requires a Guardian pipeline to be setup.
    It requires an error handler.

    These can be set either:

    1. Upstream on the connection with `plug Guardian.Pipeline`
    2. Upstream on the connection with `Guardian.Pipeline.{put_module, put_error_handler, put_key}`
    3. Inline with an option of `:module`, `:error_handler`, `:key`

    If a token is found but is invalid, the error handler will be called with
    `auth_error(conn, {:invalid_token, reason}, opts)`

    Once a token has been found it will be decoded, the token and claims will be put onto the connection.

    They will be available using `Guardian.Plug.current_claims/2` and `Guardian.Plug.current_token/2`

    Options:

    * `claims` - The literal claims to check to ensure that a token is valid
    * `realm` - The prefix for the token in the Authorization header. Defaults to `Bearer`. `:none` will not use a prefix.
    * `key` - The location to store the information in the connection. Defaults to: `default`

    ### Example

    ```elixir

    # setup the upstream pipeline

    plug BtrzAuth.Plug.VerifyHeaderInternal, claims: %{typ: "access"}

    ```

    This will check the authorization header for a token

    `Authorization Bearer: <token>`

    This token will be placed into the connection depending on the key and can be accessed with
    `Guardian.Plug.current_token` and `Guardian.Plug.current_claims`

    OR

    `MyApp.ImplementationModule.current_token` and `MyApp.ImplementationModule.current_claims`
    """
    import Plug.Conn

    alias Guardian.Plug, as: GPlug
    alias GPlug.Pipeline

    require Logger

    @spec init(Keyword.t()) :: Keyword.t()
    def init(opts \\ []) do
      opts =
        Keyword.put(
          opts,
          :main_secret,
          Keyword.get(Application.get_env(:btrz_ex_auth_api, :token, []), :main_secret, "")
        )

      opts =
        Keyword.put(
          opts,
          :secondary_secret,
          Keyword.get(Application.get_env(:btrz_ex_auth_api, :token, []), :secondary_secret, "")
        )

      realm = Keyword.get(opts, :realm, "Bearer")

      case realm do
        "" ->
          opts

        :none ->
          opts

        _realm ->
          {:ok, reg} = Regex.compile("#{realm}\:?\s+(.*)$", "i")
          Keyword.put(opts, :realm_reg, reg)
      end
    end

    @spec call(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
    def call(conn, opts) do
      Logger.debug("accessing VerifyToken plug..")
      verify(Mix.env(), conn, opts)
    end

    @spec verify(atom, Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
    defp verify(:test, conn, opts) do
      case fetch_token_from_header(conn, opts) do
        :no_token_found ->
          response_error(conn, :no_token_found, opts)

        {:ok, "test-token"} ->
          Logger.debug("using test-token mode")

          conn
          |> GPlug.put_current_token("test-token")
          |> GPlug.put_current_claims(%{})

        {:ok, _local_test_token} ->
          Logger.debug("using local test mode")
          verify(:local_test, conn, opts)
      end
    end

    defp verify(_env, conn, opts) do
      with nil <- GPlug.current_token(conn, opts),
           {:ok, token} <- fetch_token_from_header(conn, opts),
           claims_to_check <- Keyword.get(opts, :claims, %{}),
           key <- storage_key(conn, opts),
           {:ok, btrz_token_type, claims} <- decode_and_verify(conn, token, claims_to_check, opts) do
        Logger.debug("passing VerifyToken plug..")

        conn
        |> put_private(:user_id, claims["sub"])
        |> put_private(:btrz_token_type, btrz_token_type)
        |> GPlug.put_current_token(token, key: key)
        |> GPlug.put_current_claims(claims, key: key)
      else
        :no_token_found ->
          response_error(conn, :no_token_found, opts)

        {:error, reason} ->
          response_error(conn, reason, opts)

        _ ->
          conn
      end
    end

    @spec response_error(Plug.Conn.t(), any, Keyword.t()) :: Plug.Conn.t()
    defp response_error(conn, reason, opts) do
      conn
      |> Pipeline.fetch_error_handler!(opts)
      |> apply(:auth_error, [conn, {:unauthenticated, reason}, opts])
      |> halt()
    end

    @spec decode_and_verify(
            Plug.Conn.t(),
            Guardian.Token.token(),
            Guardian.Token.claims(),
            Keyword.t()
          ) :: {:ok, BtrzTokenType.t(), Guardian.Token.claims()} | {:error, any}
    defp decode_and_verify(conn, token, claims_to_check, opts) do
      opts = Keyword.put(opts, :secret, conn.private.application["privateKey"])

      case Guardian.decode_and_verify(BtrzAuth.GuardianUser, token, claims_to_check, opts) do
        {:ok, claims} ->
          {:ok, :user, claims}

        _ ->
          Logger.debug("token not valid as user token, checking if it is an internal token..")
          opts = Keyword.put(opts, :secret, opts[:main_secret])
          opts = Keyword.put(opts, :verify_issuer, true)

          case Guardian.decode_and_verify(BtrzAuth.Guardian, token, claims_to_check, opts) do
            {:ok, claims} ->
              {:ok, :internal, claims}

            _ ->
              Logger.debug(
                "main secret is not valid for internal auth, using the secondary secret.."
              )

              opts = Keyword.put(opts, :secret, opts[:secondary_secret])

              case Guardian.decode_and_verify(BtrzAuth.Guardian, token, claims_to_check, opts) do
                {:ok, claims} ->
                  {:ok, :internal, claims}

                {:error, reason} ->
                  Logger.debug("secondary secret is not valid for internal auth")
                  {:error, reason}
              end
          end
      end
    end

    @spec fetch_token_from_header(Plug.Conn.t(), Keyword.t()) ::
            :no_token_found
            | {:ok, String.t()}
    defp fetch_token_from_header(conn, opts) do
      headers = get_req_header(conn, "authorization")
      fetch_token_from_header(conn, opts, headers)
    end

    @spec fetch_token_from_header(Plug.Conn.t(), Keyword.t(), Keyword.t()) ::
            :no_token_found
            | {:ok, String.t()}
    defp fetch_token_from_header(_, _, []), do: :no_token_found

    defp fetch_token_from_header(conn, opts, [token | tail]) do
      reg = Keyword.get(opts, :realm_reg, ~r/^(.*)$/)
      trimmed_token = String.trim(token)

      case Regex.run(reg, trimmed_token) do
        [_, match] -> {:ok, String.trim(match)}
        _ -> fetch_token_from_header(conn, opts, tail)
      end
    end

    @spec storage_key(Plug.Conn.t(), Keyword.t()) :: String.t()
    defp storage_key(conn, opts), do: Pipeline.fetch_key(conn, opts)
  end
end
