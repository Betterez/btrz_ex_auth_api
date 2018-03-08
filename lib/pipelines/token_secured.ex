defmodule BtrzAuth.Pipelines.TokenSecured do
  use Guardian.Plug.Pipeline, otp_app: :btrz_auth

  plug Guardian.Plug.VerifyHeader
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource, allow_blank: true # remove this option if always will load the account
end