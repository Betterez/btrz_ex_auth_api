use Mix.Config

# Guardian configuration
config :btrz_auth, BtrzAuth.Guardian,
  issuer: "btrz-api-client",
  secret_key: System.get_env("GUARDIAN_SECRET_KEY") || "SZE3PMBmMt90TaCcaDjs8go/mWsf2rbmi5FRdoZC5OxxXrXjn8GadonjHOkdkKmx"

config :btrz_auth, BtrzAuth.GuardianInternal,
  issuer: "btrz-api-client",
  secret_key: System.get_env("GUARDIAN_SECRET_KEY") || "UyE3PMBmMCcaDjs8go/mWt90Taop90Gadobmi5FRdoZC5OxxXrXjn8njHOxkdkKm"
