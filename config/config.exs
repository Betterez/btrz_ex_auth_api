use Mix.Config

config :btrz_auth, :token, []

if Mix.env() == :test, do: import_config("test.exs")
