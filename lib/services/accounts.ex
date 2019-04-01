defmodule BtrzAuth.Services.Accounts do
  def get_application(api_key, path \\ "application") do
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
        body = Jason.decode!(body)

        if Map.has_key?(body, "application") do
          {:ok, body["application"]}
        else
          {:ok, body}
        end

      {:ok, response} ->
        {:error, response}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end
end
