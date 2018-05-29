defmodule BtrzAuth.Pipeline.TokenSecured do
  @moduledoc """

  This pipeline will check the x-api-key header and also the token with the private key or the configured main and secondary secret keys in case the token could be an internal one, then ensure authenticated and load the implemented resource in `conn.private[:application]`.
  """
  use Guardian.Plug.Pipeline,
    otp_app: :btrz_ex_auth_api,
    error_handler: BtrzAuth.AuthErrorHandler

  plug(BtrzAuth.Plug.VerifyApiKey)
  plug(BtrzAuth.Plug.VerifyToken)
  plug(Guardian.Plug.EnsureAuthenticated)
end
