defmodule BtrzAuth.Pipelines.ApiKeySecured do
  use Guardian.Plug.Pipeline,
    otp_app: :btrz_auth,
    module: BtrzAuth.GuardianInternal,
    error_handler: BtrzAuth.AuthErrorHandler

  plug(BtrzAuth.Plug.VerifyApiKey)
  plug(Guardian.Plug.LoadResource, allow_blank: true)
end
