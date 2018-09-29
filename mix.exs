defmodule Decorator.Mixfile do
  use Mix.Project

  def project do
    [
      app: :decorator,
      version: File.read!("VERSION"),
      elixir: "~> 1.3",
      elixirc_options: [warnings_as_errors: true],
      description: description(),
      package: package(),
      source_url: "https://github.com/arjan/decorator",
      homepage_url: "https://github.com/arjan/decorator",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  defp description do
    "Function decorators for Elixir"
  end

  defp package do
    %{
      files: ["lib", "mix.exs", "*.md", "LICENSE", "VERSION"],
      maintainers: ["Arjan Scherpenisse"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/arjan/decorator"}
    }
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    []
  end
end
