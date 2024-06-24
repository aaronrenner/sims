defmodule Sims.Integration.MixProject do
  use Mix.Project

  def project do
    [
      app: :sims_integration,
      version: "0.1.0",
      elixir: "~> 1.13",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:bandit, "~> 1.0"},
      {:bypass, "~> 2.1"},
      {:plug, "~> 1.13"},
      {:req, "~> 0.5.1", only: :test},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false}
    ]
  end
end
