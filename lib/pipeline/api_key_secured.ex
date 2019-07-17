defmodule BtrzAuth.Pipeline.ApiKeySecured do
  @moduledoc """

  This pipeline will check the x-api-key header is sent and load the implemented resource in `conn.private[:account]`.
  """
  use Guardian.Plug.Pipeline,
    otp_app: :btrz_ex_auth_api,
    error_handler: BtrzAuth.AuthErrorHandler

  plug(BtrzAuth.Plug.VerifyApiKey)
end
