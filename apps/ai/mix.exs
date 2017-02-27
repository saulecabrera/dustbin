defmodule AI.Mixfile do
  use Mix.Project

  def project do
    [app: :ai,
     version: "0.1.0",
     build_path: "../../_build",
     config_path: "../../config/config.exs",
     deps_path: "../../deps",
     lockfile: "../../mix.lock",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [:logger],
     mod: {AI.Application, []}]
  end

  defp deps do
    [
      {:elixir_wit, "~> 1.0.0"},
    ]
  end
end
