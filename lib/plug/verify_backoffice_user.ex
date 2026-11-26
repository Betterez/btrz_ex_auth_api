if Code.ensure_loaded?(Plug) do
  defmodule BtrzAuth.Plug.VerifyBackofficeUser do
    @moduledoc """
    Lets a request through only when its token was issued to one of the account's back-office users, or, unless
    `allow_internal: false`, when it is an internal service token.

    It depends on `BtrzAuth.Plug.VerifyToken` (or `BtrzAuth.Pipeline.TokenSecured`), which must run first.

    * Customer tokens are refused: tokens with the audience "customer", and tokens that carry a customer (a
      `customerNumber` claim) whatever their audience. They are issued to an account's customers, not to the
      people who manage the account.
    * Any other user token must name the user it was issued to, in its `id` claim or, as long user tokens and
      application tokens carry it, its `_id` claim. That id is stored in `conn.private[:user_id]`, where
      `BtrzAuth.Plug.VerifyToken` stores the `id` claim.
    * Internal service tokens carry no user. They pass by default, leaving `conn.private[:user_id]` as it is.

    Refused requests are halted with a 401 and this body:

    ```elixir
    %{
      "error" => "unauthorized",
      "reason" => "backoffice_user_required"
    }
    ```

    Options:

    * `allow_internal` - whether internal service tokens pass. Defaults to `true`.

    ### Example

    ```elixir
    pipeline :backoffice_user do
      plug BtrzAuth.Pipeline.TokenSecured
      plug BtrzAuth.Plug.VerifyBackofficeUser
    end
    ```
    """
    import Plug.Conn

    require Logger

    @customer_audience "customer"

    @spec init(Keyword.t()) :: Keyword.t()
    def init(opts \\ []) do
      Keyword.put_new(opts, :allow_internal, true)
    end

    @spec call(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
    def call(%Plug.Conn{private: %{btrz_token_type: :internal}} = conn, opts) do
      if Keyword.get(opts, :allow_internal, true) do
        conn
      else
        refuse(conn)
      end
    end

    def call(conn, _opts) do
      claims = Guardian.Plug.current_claims(conn) || %{}

      with false <- customer?(conn, claims),
           user_id when is_binary(user_id) and user_id != "" <- user_id(conn, claims) do
        put_private(conn, :user_id, user_id)
      else
        _ -> refuse(conn)
      end
    end

    defp customer?(conn, claims) do
      conn.private[:user_aud] == @customer_audience or claims["aud"] == @customer_audience or
        Map.has_key?(claims, "customerNumber")
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
