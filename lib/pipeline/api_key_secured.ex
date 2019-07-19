defmodule BtrzAuth.Pipeline.ApiKeySecured do
  @moduledoc """

  This pipeline will:
  1. Check the x-api-key header is sent and load the implemented resource in `conn.private[:account]`.
  2. Validate the providers if passed via query params.
  3. Add the premium keys of the providers to the ones of the current account.
  """
  use Guardian.Plug.Pipeline,
    otp_app: :btrz_ex_auth_api,
    error_handler: BtrzAuth.ErrorHandler

  plug(BtrzAuth.Plug.VerifyApiKey)
  plug(BtrzAuth.Plug.VerifyProviders)
  plug(BtrzAuth.Plug.AddPremiumFromProviders)
end
