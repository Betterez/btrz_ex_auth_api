if Code.ensure_loaded?(Plug) do
  defmodule BtrzAuth.Plug.VerifyAudiences do
    @moduledoc """

    Looks for and validates that the passed `audiences` are present in the private data under `conn.private.user_aud`
    saved by `BtrzAuth.Plug.VerifyToken` (the order of the plugs is very important!)

    If the audiences are invalid, the pipeline will be halted and the `conn.resp_body` with:

    ```elixir
    %{
      "error" => "unauthorized",
      "reason" => "audiences_not_verified"
    }
    ```

    Options:

    * `audiences` - list of atom audiences to verify. Please use the ones found on BtrzAuth.Audiences.valid_audiences

    ### Example

    ```elixir
    plug BtrzAuth.Plug.VerifyAudiences, audiences: [:CUSTOMER]

    ```
    """
    import Plug.Conn
    alias BtrzAuth.Audiences
    require Logger

    @spec init(Keyword.t()) :: Keyword.t()
    def init(opts) do
      audiences = Keyword.get(opts, :audiences, [])
      maybe_put_audiences_in_opts(opts, audiences)
    end

    defp maybe_put_audiences_in_opts(opts, []), do: invalid_audiences_response()
    defp maybe_put_audiences_in_opts(opts, audiences) do
      audiences
        |> Enum.all?(fn audience -> Enum.member?(Audiences.valid_audiences, audience) end)
        |> case do
          true -> Keyword.put(opts, :audiences, audiences)
          false -> invalid_audiences_response()
        end
    end

    defp invalid_audiences_response(), do: {:error, "invalid_audiences"}

    @spec call(Plug.Conn.t(), Keyword.t()) :: Plug.Conn.t()
    def call(%Plug.Conn{private: %{user_aud: user_aud}} = conn, opts) do
      audiences = opts[:audiences]
      with true <- Map.has_key?(Audiences.valid_audiences_map, user_aud) do
        audiences
          |> Enum.any?(fn audience -> Map.get(Audiences.valid_audiences_map, user_aud) == audience end)
          |> case do
            true -> conn
            false -> unauthorized_audience(conn)
          end
      else
        false -> unauthorized_audience(conn)
      end
    end

    defp unauthorized_audience(conn) do
      conn
        |> BtrzAuth.ErrorHandler.auth_error({:unauthorized, :audience_not_verified})
        |> halt()
    end
  end
end
