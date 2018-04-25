# BtrzAuth

[![Build status badge](https://img.shields.io/circleci/project/github/Betterez/btrz_ex_auth_api/master.svg)](https://circleci.com/gh/Betterez/btrz_ex_auth_api/tree/master)

Elixir package for authentication handling using Plug and Guardian (JWT).
It supports `X-API-KEY` token and `Authorization` tokens, for external users or internal API communication.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `btrz_auth` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:btrz_auth, "~> 0.3.0"}
  ]
end
```

Add your configuration

```elixir
config :btrz_auth, :token,
    issuer: "your-issuer",
    main_secret: "YOUR_MAIN_KEY",
    secondary_secret: "YOUR_SECONDARY_KEY"
```

## Plugs
You can use the [Guardian Plugs](https://hexdocs.pm/guardian/readme.html#plugs) and the ones added by BtrzAuth:

#### `BtrzAuth.Plug.VerifyApiKey`

Looks for the header `X_API_KEY` and verify the account, saving it into `conn.private[:auth_user]`.

#### `BtrzAuth.Plug.VerifyToken`

It depends on `BtrzAuth.Plug.VerifyApiKey`, looks for a token in the `Authorization` header and verify it using first the account's private key, if not valid, then main and secondary secrets provided by your app for internal token cases.
## Pipelines

### BtrzAuth.Pipeline.ApiKeySecured

This pipeline will check the x-api-key header is sent and load the implemented resource in `conn.private[:auth_user]`.

* plug BtrzAuth.Plug.VerifyApiKey
* plug Guardian.Plug.LoadResource
### BtrzAuth.Pipeline.TokenSecured

This pipeline will check the x-api-key header and also the token with the private key or the configured main and secondary secret keys in case the token could be an internal one, then ensure authenticated and load the implemented resource in the `conn.private[:auth_user]`.

* plug BtrzAuth.Plug.VerifyApiKey
* plug BtrzAuth.Plug.VerifyToken
* plug Guardian.Plug.EnsureAuthenticated
* plug Guardian.Plug.LoadResource

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

## Integration tests in your API
Add the test_resource in order to test your endpoints once the plugs or pipelines are defined:

```elixir
config :btrz_auth, :token,
    issuer: "your-issuer",
    main_secret: "YOUR_MAIN_KEY",
    secondary_secret: "YOUR_SECONDARY_KEY"
    test_resource: %{account_id: "DESIRED_ID"}
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/btrz_auth](https://hexdocs.pm/btrz_auth).

