defmodule BtrzAuth.Services.Accounts do
  def get_account_auth_info(api_key, path \\ "account-auth-info") do
    url = "#{Application.get_env(:btrz_ex_auth_api, :services)[:accounts_url]}#{path}"

    {:ok, token, _claims} =
      BtrzAuth.internal_auth_token(Application.get_env(:btrz_ex_auth_api, :token))

    headers = [
      Authorization: "Bearer #{token}",
      Accept: "Application/json; Charset=utf-8",
      "x-api-key": api_key
    ]

    case HTTPoison.get(url, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        {:ok, Jason.decode!(body)}

      {:ok, response} ->
        {:error, response}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end
end
