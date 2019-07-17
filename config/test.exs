use Mix.Config

config :btrz_ex_auth_api, :token,
  issuer: "btrz-api-client",
  main_secret: "Hf45fFc89SJ204kowbPIQ3Ui2Oxn2a8OWlEi6RTkuOd0jHvZiZh0EWwOxSVul5eS",
  secondary_secret: "0IAWv5Qe1Mvp5x5xtv1rpxFsO38ylCSXV6uQktSIGoQob79ELkjbNQUWIxOKoaU4",
  test_resource: %{"id" => "gj66MrTI5t2", "private_key" => "123"}

config :btrz_ex_auth_api, :services, accounts_url: "http://httpbin.org/"
