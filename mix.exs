defmodule MDExMermex.MixProject do
  use Mix.Project

  @version "0.1.0"
  @source_url "https://github.com/frankdugan3/mdex_mermex"
  @description "An MDEx plugin that renders Mermaid diagrams server-side using Mermex (Rust NIF)"

  def project do
    [
      app: :mdex_mermex,
      version: @version,
      elixir: "~> 1.19",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "MDExMermex",
      description: @description,
      source_url: @source_url,
      homepage_url: @source_url,
      package: package(),
      docs: docs(),
      dialyzer: [
        plt_local_path: "_build/dialyzer/"
      ]
    ]
  end

  def cli do
    [preferred_envs: [check: :test, credo: :test, dialyzer: :test]]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp package do
    [
      name: "mdex_mermex",
      licenses: ["MIT"],
      links: %{
        "GitHub" => @source_url,
        "Changelog" => "#{@source_url}/blob/main/CHANGELOG.md"
      },
      files: ~w(lib assets .formatter.exs mix.exs README.md LICENSE CHANGELOG.md)
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "v#{@version}",
      extras: ["README.md", "CHANGELOG.md", "LICENSE"]
    ]
  end

  defp deps do
    [
      {:mdex, "~> 0.4"},
      {:mermex, "~> 0.1.0"},
      {:ex_doc, "~> 0.40", only: :dev, runtime: false},
      {:ex_check, "~> 0.16", only: [:dev, :test], runtime: false},
      {:git_ops, "~> 2.6", only: :dev, runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:mix_audit, "~> 2.1", only: [:dev, :test], runtime: false},
      {:doctor, "~> 0.22", only: [:dev, :test], runtime: false}
    ]
  end
end
