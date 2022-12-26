defmodule BtrzAuth.MixProject do
  use Mix.Project

  @github_url "https://github.com/Betterez/btrz_ex_auth_api"
  @version "1.2.0"

  def project do
    [
      app: :btrz_ex_auth_api,
      version: @version,
      name: "BtrzAuth",
      description: "Elixir package for authentication handling using Plug and Guardian (JWT)",
      source_url: @github_url,
      homepage_url: @github_url,
      elixir: "~> 1.5",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package(),
      aliases: aliases(),
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [coveralls: :test]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:plug, "~> 1.4"},
      {:guardian, "~> 1.0"},
      {:excoveralls, "~> 0.8", only: :test},
      {:httpoison, "~> 1.0"},
      {:jason, "~> 1.1"},
      {:junit_formatter, "~> 2.1", only: :test}
    ]
  end

  defp docs do
    [
      main: "BtrzAuth",
      source_ref: "v#{@version}",
      source_url: @github_url,
      extras: ["README.md"],
      groups_for_modules: groups_for_modules()
    ]
  end

  defp groups_for_modules do
    # Ungrouped:
    # - BtrzAuth

    [
      "Token Providers": [
        BtrzAuth.Providers.InternalToken,
        BtrzAuth.Providers.UserToken
      ],
      Plugs: [
        BtrzAuth.Plug.VerifyApiKey,
        BtrzAuth.Plug.VerifyPremium,
        BtrzAuth.Plug.VerifyToken,
        BtrzAuth.Plug.VerifyProviders,
        BtrzAuth.Plug.AddPremiumFromProviders,
        BtrzAuth.Plug.VerifyAudiences
      ],
      Pipelines: [
        BtrzAuth.Pipeline.ApiKeySecured,
        BtrzAuth.Pipeline.TokenSecured
      ],
      Phoenix: [
        BtrzAuth.Phoenix.SocketAuth
      ],
      Services: [
        BtrzAuth.Services.Accounts
      ]
    ]
  end

  defp aliases do
    [
      test: ["coveralls.html"]
    ]
  end

  defp package do
    %{
      name: "btrz_ex_auth_api",
      licenses: ["MIT"],
      maintainers: ["Hernán García", "Pablo Brudnick"],
      links: %{"GitHub" => @github_url}
    }
  end
end
