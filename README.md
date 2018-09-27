# BtrzAuth

[![Build status badge](https://img.shields.io/circleci/project/github/Betterez/btrz_ex_auth_api/master.svg)](https://circleci.com/gh/Betterez/btrz_ex_auth_api/tree/master)

Elixir package for authentication handling using Plug and Guardian (JWT).
It supports `X-API-KEY` token and `Authorization` tokens, for external users or internal API communication.

## Documentation

API documentation at HexDocs [https://hexdocs.pm/btrz_ex_auth_api](https://hexdocs.pm/btrz_ex_auth_api)

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `btrz_auth` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:btrz_ex_auth_api, "~> 0.7.0"}]
end
```

Add your configuration

```elixir
config :btrz_ex_auth_api, :token,
    issuer: "your-issuer",
    main_secret: "YOUR_MAIN_KEY",
    secondary_secret: "YOUR_SECONDARY_KEY"
```

## Plugs
You can use the [Guardian Plugs](https://hexdocs.pm/guardian/readme.html#plugs) and the ones added by BtrzAuth:

#### `BtrzAuth.Plug.VerifyApiKey`

Looks for the header or querystring `x-api-key` and verify the account, saving it into `conn.private[:application]`.

#### `BtrzAuth.Plug.VerifyToken`

It depends on `BtrzAuth.Plug.VerifyApiKey`, looks for a token in the `Authorization` header and verify it using first the account's private key loading the user id in the `conn.private[:user_id], if not valid, then main and secondary secrets provided by your app for internal token cases.

#### `BtrzAuth.Plug.VerifyPremium`

Looks for and validates that the passed `keys` features are present in the saved claims under `conn.private` using `BtrzAuth.Guardian.Plug.current_claims(conn)`.

## Pipelines

### BtrzAuth.Pipeline.ApiKeySecured

This pipeline will check the `x-api-key` header or querystring is sent and load the implemented resource in `conn.private[:application]`.

* plug BtrzAuth.Plug.VerifyApiKey

### BtrzAuth.Pipeline.TokenSecured

This pipeline will check the `x-api-key` header loading the application data in `conn.private[:application]` and also the token with the private key or the configured main and secondary secret keys in case the token could be an internal one, then ensure authenticated and load the implemented resource id in the `conn.private[:user_id]`.

* plug BtrzAuth.Plug.VerifyApiKey
* plug BtrzAuth.Plug.VerifyToken
* plug Guardian.Plug.EnsureAuthenticated

You can add pipelines in your Phoenix Router to get different authentication working.

```elixir
pipeline :token_secured do
  plug BtrzAuth.Pipelines.TokenSecured
end

scope "/" do
  pipe_through :token_secured
  # your routes here...
end
```

## Phoenix Channels
For Phoenix socket auth we wrap the `Guardian.Phoenix.Socket` module in order to use our `internal-token`, you might add to your `user_socket.ex`:

```elixir
def connect(%{"token" => token}, socket) do
  case BtrzAuth.Phoenix.SocketAuth.authenticate(socket, token) do
    {:ok, authed_socket} ->
      {:ok, authed_socket}
    {:error, _} -> :error
  end
end

def connect(_params, _socket) do
  :error
end
```

## Integration tests in your API
Add the test_resource in order to test your endpoints once the plugs or pipelines are defined:

```elixir
config :btrz_ex_auth_api, :token,
    issuer: "your-issuer",
    main_secret: "YOUR_MAIN_KEY",
    secondary_secret: "YOUR_SECONDARY_KEY"
    test_resource: %{account_id: "DESIRED_ID"}
```

and use `"test-token"` as your test token in the `Authorization` header.

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/btrz_auth](https://hexdocs.pm/btrz_auth).

