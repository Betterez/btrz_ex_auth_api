defmodule BtrzAuth.Pipeline.TokenSecured do
  use Guardian.Plug.Pipeline,
    otp_app: :btrz_auth,
    module: BtrzAuth.Guardian,
    error_handler: BtrzAuth.AuthErrorHandler

  plug(BtrzAuth.Plug.VerifyApiKey)
  plug(Guardian.Plug.VerifyHeader)
  plug(Guardian.Plug.EnsureAuthenticated)
  # remove this option if always will load the account
  plug(Guardian.Plug.LoadResource, allow_blank: true)
end
