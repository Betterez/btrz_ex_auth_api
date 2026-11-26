if Code.ensure_loaded?(Plug) do
  defmodule BtrzAuth.Plug.VerifyInternal do
    @moduledoc """
    Lets a request through only when its token is an internal service token, signed with the main or secondary
    secret.

    It depends on `BtrzAuth.Plug.VerifyToken` (or `BtrzAuth.Pipeline.TokenSecured`), which must run first.

    Use it on routes that only other Betterez services call, such as ones that store data a worker will act on
    later. User, customer and application tokens are all refused, as is the `"test-token"` that `VerifyToken`
    accepts in the test environment: tests should send a real internal token (`BtrzAuth.internal_auth_token/1`).

    Refused requests are halted with a 401 and this body:

    ```elixir
    %{
      "error" => "unauthorized",
      "reason" => "internal_token_required"
    }
    ```

    ### Example

    ```elixir
    pipeline :internal_only do
      plug BtrzAuth.Pipeline.TokenSecured
      plug BtrzAuth.Plug.VerifyInternal
    end
    ```
    """
    import Plug.Conn

    require Logger

    @spec init(Keyword.t()) :: Keyword.t()
    def init(opts \\ []), do: opts

    @spec call(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
    def call(%Plug.Conn{private: %{btrz_token_type: :internal}} = conn, _opts), do: conn

    def call(conn, _opts) do
      Logger.warn(
        "refusing a request without an internal token, token type: #{inspect(conn.private[:btrz_token_type])}, audience: #{inspect(conn.private[:user_aud])}"
      )

      conn
      |> BtrzAuth.ErrorHandler.auth_error({:unauthorized, :internal_token_required})
      |> halt()
    end
  end
end
