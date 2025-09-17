defmodule MetricsAgent.MixProject do
  use Mix.Project

  def project do
    [
      app: :metrics_agent,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {MetricsAgent.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # MQTT client
      {:tortoise, "~> 0.10"},

      # JSON handling
      {:jason, "~> 1.4"}
    ]
  end
end
