defmodule Sims.MixProject do
  use Mix.Project

  def project do
    [
      app: :sims,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      dialyzer: dialyzer(System.get_env()),
      aliases: aliases()
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
      {:igniter, "~> 0.5"},
      {:tidewave, "~> 0.2", only: :dev},
      {:bandit, "~> 1.0", only: :dev},
      {:ex_doc, "~> 0.34", only: :dev, runtime: false, warn_if_outdated: true},
      {:dialyxir, "~> 1.1", only: [:dev], runtime: false},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false}
    ]
  end

  # Environment specific dialyzer confi
  defp dialyzer(%{"CI" => "true"}) do
    [
      plt_core_path: ".dialyzer/core",
      plt_local_path: ".dialyzer/local",
      plt_add_apps: [:mix]
    ]
  end

  defp dialyzer(_), do: []

  defp aliases do
    [
      tidewave:
        "run --no-halt -e 'Agent.start(fn -> Bandit.start_link(plug: Tidewave, port: 4000) end)'"
    ]
  end
end
