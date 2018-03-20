# BtrzAuth

Elixir package for authentication handling using Plug and Guardian (JWT).

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `btrz_auth` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:btrz_auth, "~> 0.1.0"}
  ]
end
```

Add your configuration

```elixir
config :btrz_auth, :token,
    issuer: "your-issuer",
    main_secret: "YOUR_MAIN_KEY",
    secondary_secret: "YOUR_SECONDARY_KEY"

config :btrz_auth, :db,
    uris: ["127.0.0.1:27017"],
    database: "dbname",
    username: "",
    password: "",
    collection_name: "accounts",
    property: "token"
```

## Plugs
You can use the [Guardian Plugs](https://hexdocs.pm/guardian/readme.html#plugs) and the ones added by BtrzAuth:
#### `BtrzAuth.Plug.VerifyHeaderInternal`

Look for a token in the header and verify it using main and secondary secrets provided by your app.

#### `BtrzAuth.Plug.VerifyApiKey`

Look for the header `X_API_KEY` and verify against a mongodb document resource, saving it into the `conn`.
## Pipelines

### api_key_secured

This pipeline will check the x-api-key header is sent with a token and load the implemented resource in the `conn`.

* plug BtrzAuth.Plug.VerifyApiKey
* plug Guardian.Plug.LoadResource
### token_secured

This pipeline will check the internal token with the configured main and secondary secret keys, then ensure authenticated and load the implemented resource in the `conn`.

* plug BtrzAuth.Plug.VerifyApiKey
* plug BtrzAuth.Plug.VerifyHeaderInternal
* plug Guardian.Plug.EnsureAuthenticated
* plug Guardian.Plug.LoadResource

Adding pipelines in the Phoenix router to require authentication.

```elixir
pipeline :token_secured do
  plug BtrzAuth.Pipelines.TokenSecured
end

scope "/" do
  pipe_through :token_secured
  # your routes here...
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/btrz_auth](https://hexdocs.pm/btrz_auth).

