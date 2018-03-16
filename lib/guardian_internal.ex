defmodule BtrzAuth.GuardianInternal do
  use Guardian, otp_app: :btrz_auth

  def subject_for_token(resource, _claims) when resource == %{} do
    {:ok, %{}}
  end

  def subject_for_token(_, _) do
    {:error, :invalid_resource}
  end

  def resource_from_claims(claims) do
    resource = claims["sub"]
    {:ok, resource}
  end
end
