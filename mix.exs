defmodule RequestInspector.MixProject do
  use Mix.Project

  def project do
    [
      app: :request_inspector,
      version: "1.1.5",
      elixir: "~> 1.6",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      applications: [:cowboy, :plug, :poison],   # Although it seems to work without this line; Plug docs say this should be added
      extra_applications: [:logger],
      mod: {RequestInspector, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:cowboy, "~> 2.0"},
      {:plug, "~> 1.6"},
      {:poison, "~> 3.1"},
      {:distillery, "~> 1.5"}
    ]
  end
end
