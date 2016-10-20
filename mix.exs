defmodule Decorator.Mixfile do
  use Mix.Project

  def project do
    [app: :decorator,
     version: "0.1.0",
     elixir: "~> 1.3",
     description: description(),
     package: package(),
     source_url: "https://github.com/arjan/decorator",
     homepage_url: "https://github.com/arjan/decorator",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps()]
  end

  defp description do
    "Function decorators for Elixir"
  end

  defp package do
    %{files: ["lib", "mix.exs",
              "*.md", "LICENSE"],
      maintainers: ["Arjan Scherpenisse"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/arjan/decorator"}}
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    []
  end
end
