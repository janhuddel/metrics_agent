defmodule MetricsAgent.MixProject do
  use Mix.Project

  def project do
    [
      app: :metrics_agent,
      version: version(),
      elixir: "~> 1.17",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Get version from git tag or use -dev suffix if not on a tag
  defp version do
    case System.cmd("git", ["describe", "--tags", "--exact-match", "HEAD"],
           stderr_to_stdout: true
         ) do
      {tag, 0} ->
        # We're on an exact tag, remove the 'v' prefix if present
        tag |> String.trim() |> String.replace_leading("v", "")

      _ ->
        # Not on an exact tag, get the latest tag and add -dev
        case System.cmd("git", ["describe", "--tags", "--abbrev=0"], stderr_to_stdout: true) do
          {latest_tag, 0} ->
            latest_tag |> String.trim() |> String.replace_leading("v", "") |> Kernel.<>("-dev")

          _ ->
            # No tags found, use default version
            "0.0.0-dev"
        end
    end
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
      # JSON handling
      {:jason, "~> 1.4"},

      # TOML configuration parsing
      {:toml, "~> 0.6"},

      # MQTT client (https://github.com/emqx/emqtt/issues/289)
      {:emqtt,
       git: "https://github.com/emqx/emqtt.git",
       tag: "1.14.4",
       system_env: [{"BUILD_WITHOUT_QUIC", "1"}]}
    ]
  end
end
