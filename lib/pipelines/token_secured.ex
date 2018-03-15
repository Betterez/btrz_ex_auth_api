defmodule BtrzAuth.Pipelines.TokenSecured do
  use Guardian.Plug.Pipeline, otp_app: :btrz_auth,
    module: BtrzAuth.GuardianInternal,
    error_handler: BtrzAuth.AuthErrorHandler

  plug BtrzAuth.Plug.VerifyApiKey
  plug BtrzAuth.Plug.VerifyHeaderInternal
  plug Guardian.Plug.EnsureAuthenticated
  plug Guardian.Plug.LoadResource, allow_blank: true # remove this option if always will load the account
end
