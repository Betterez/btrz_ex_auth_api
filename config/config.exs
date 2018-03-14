use Mix.Config

config :btrz_auth, BtrzAuth.GuardianInternal, []

if Mix.env() == :test, do: import_config("test.exs")
