defmodule Unclog.MixProject do
  use Mix.Project

  def project do
    [
      app: :unclog,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      description: description(),
      deps: deps(),
      package: package(),
      # Docs
      name: "Unclog",
      source_url: "https://github.com/m1dnight/unclog",
      homepage_url: "https://github.com/m1dnight/unclog",
      docs: &docs/0
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
      {:timex, "~> 3.7"},
      {:dialyxir, "~> 1.4", only: [:dev, :test], runtime: false},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      # The main page in the docs
      main: "Unclog",
      extras: ["README.md"]
    ]
  end

  defp description() do
    "Unclog helps you manage changelog files."
  end

  defp package() do
    [
      # This option is only needed when you don't want to use the OTP application name
      name: "unclog",
      # These are the default files included in the package
      files: ~w(lib .formatter.exs mix.exs README* LICENSE*
                CHANGELOG*),
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/m1dnight/unclog"}
    ]
  end
end
