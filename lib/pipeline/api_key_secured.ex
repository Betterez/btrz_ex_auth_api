defmodule BtrzAuth.Pipeline.ApiKeySecured do
  @moduledoc """

  This pipeline will check the x-api-key header is sent and load the implemented resource in `conn.private[:auth_user]`.
  """
  use Guardian.Plug.Pipeline,
    otp_app: :btrz_auth,
    module: BtrzAuth.GuardianInternal,
    error_handler: BtrzAuth.AuthErrorHandler

  plug(BtrzAuth.Plug.VerifyApiKey)
end
