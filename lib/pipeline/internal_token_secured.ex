defmodule BtrzAuth.Pipeline.InternalTokenSecured do
  use Guardian.Plug.Pipeline,
    otp_app: :btrz_auth,
    module: BtrzAuth.GuardianInternal,
    error_handler: BtrzAuth.AuthErrorHandler

  plug(BtrzAuth.Plug.VerifyApiKey)
  plug(BtrzAuth.Plug.VerifyHeaderInternal)
  plug(Guardian.Plug.EnsureAuthenticated)
  # remove this option if always will load the account
  plug(Guardian.Plug.LoadResource, allow_blank: true)
end
