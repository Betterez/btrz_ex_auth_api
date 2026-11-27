if Code.ensure_loaded?(Plug) do
  defmodule BtrzAuth.Plug.VerifyBackofficeUser do
    @moduledoc """
    Lets a request through only when its token was issued to one of the account's back-office users for an allowed
    audience, or, unless `allow_internal: false`, when it is an internal service token.

    It depends on `BtrzAuth.Plug.VerifyToken` (or `BtrzAuth.Pipeline.TokenSecured`), which must run first.

    * The token's audience must be one of `audiences`, which defaults to `[:BETTEREZ_APP]`. Any other audience is
      refused, including ones added after this plug was written.
    * When a back-office user logs in, the client names the application it logs in for, and that name becomes the
      token's audience. An integration that logs in for its own application gets a token with that application's
      name as its audience. To let such tokens through, list the name as a string in `audiences`. A string is
      compared exactly with the token's audience.
    * Customer tokens are always refused: their audience is `"customer"`, which can't be allowed as an atom or as a
      string.
    * The token must name the user it was issued to, in its `id` claim or, as long user tokens carry it, its `_id`
      claim. That id is stored in `conn.private[:user_id]`, where `BtrzAuth.Plug.VerifyToken` stores the `id`
      claim.
    * Internal service tokens carry no user or audience. They pass by default, leaving `conn.private[:user_id]` as
      it is.

    Refused requests are halted with a 401 and this body:

    ```elixir
    %{
      "error" => "unauthorized",
      "reason" => "backoffice_user_required"
    }
    ```

    Options:

    * `audiences` - the audiences allowed. Each is either an atom from `BtrzAuth.Audiences.valid_audiences/0` except
      `:CUSTOMER`, or a string naming an application, such as `"my-integration"`. `:CUSTOMER`, a string that names
      the customer audience in any case, an empty string, or a string with surrounding whitespace raises. Defaults
      to `[:BETTEREZ_APP]`.
    * `allow_internal` - whether internal service tokens pass. Defaults to `true`.

    ### Example

    ```elixir
    pipeline :backoffice_user do
      plug BtrzAuth.Pipeline.TokenSecured
      plug BtrzAuth.Plug.VerifyBackofficeUser, audiences: [:BETTEREZ_APP, :MOBILE_SCANNER]
    end

    pipeline :backoffice_user_or_integration do
      plug BtrzAuth.Pipeline.TokenSecured
      plug BtrzAuth.Plug.VerifyBackofficeUser, audiences: [:BETTEREZ_APP, "my-integration"]
    end
    ```
    """
    import Plug.Conn

    alias BtrzAuth.Audiences

    require Logger

    # Customer tokens are issued to an account's customers, never to its back-office users.
    @allowed_audiences Audiences.valid_audiences() -- [:CUSTOMER]

    @spec init(Keyword.t()) :: Keyword.t()
    def init(opts \\ []) do
      audiences = Keyword.get(opts, :audiences, [:BETTEREZ_APP])

      if not is_list(audiences) or audiences == [] or not Enum.all?(audiences, &allowed_option?/1) do
        raise ArgumentError,
              "audiences must be a non-empty list of #{inspect(@allowed_audiences)} or application names " <>
                "(non-empty strings without surrounding whitespace, other than \"customer\"), got: " <>
                inspect(audiences)
      end

      opts
      |> Keyword.put(:audiences, audiences)
      |> Keyword.put_new(:allow_internal, true)
    end

    @spec call(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
    def call(%Plug.Conn{private: %{btrz_token_type: :internal}} = conn, opts) do
      if Keyword.get(opts, :allow_internal, true) do
        conn
      else
        refuse(conn)
      end
    end

    def call(conn, opts) do
      claims = Guardian.Plug.current_claims(conn) || %{}

      with true <- allowed_audience?(conn, claims, opts[:audiences]),
           user_id when is_binary(user_id) and user_id != "" <- user_id(conn, claims) do
        put_private(conn, :user_id, user_id)
      else
        _ -> refuse(conn)
      end
    end

    defp allowed_option?(audience) when is_atom(audience), do: audience in @allowed_audiences

    defp allowed_option?(audience) when is_binary(audience) do
      audience != "" and String.trim(audience) == audience and not customer_audience?(audience)
    end

    defp allowed_option?(_audience), do: false

    defp customer_audience?(audience) do
      Map.get(Audiences.valid_audiences_map(), String.downcase(audience)) == :CUSTOMER
    end

    defp allowed_audience?(conn, claims, audiences) do
      case conn.private[:user_aud] || claims["aud"] do
        audience when is_binary(audience) and audience != "" ->
          not customer_audience?(audience) and
            (audience in audiences or
               Map.get(Audiences.valid_audiences_map(), audience) in audiences)

        _ ->
          false
      end
    end

    defp user_id(conn, claims) do
      conn.private[:user_id] || claims["id"] || claims["_id"]
    end

    defp refuse(conn) do
      Logger.warn(
        "refusing a request without a back-office user, token type: #{inspect(conn.private[:btrz_token_type])}, audience: #{inspect(conn.private[:user_aud])}"
      )

      conn
      |> BtrzAuth.ErrorHandler.auth_error({:unauthorized, :backoffice_user_required})
      |> halt()
    end
  end
end
