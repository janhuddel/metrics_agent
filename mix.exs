defmodule MetricsAgent.MixProject do
  use Mix.Project

  def project do
    [
      app: :metrics_agent,
      version: "0.1.0",
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: [
        metrics_agent: [
          steps: [:assemble, &Burrito.wrap/1],
          burrito: [
            targets: [
              linux: [
                os: :linux,
                cpu: :x86_64
              ]
            ]
          ]
        ]
      ]
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
      {:burrito, "~> 1.4"},

      # JSON handling
      {:jason, "~> 1.4"},

      # MQTT client (https://github.com/emqx/emqtt/issues/289)
      {:emqtt,
       git: "https://github.com/emqx/emqtt.git",
       tag: "1.14.4",
       system_env: [{"BUILD_WITHOUT_QUIC", "1"}]}
    ]
  end
end
