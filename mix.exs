defmodule Decorator.Mixfile do
  use Mix.Project

  def project do
    [
      app: :decorator,
      version: File.read!("VERSION"),
      elixir: "~> 1.5",
      elixirc_options: elixirrc_options(Mix.env()),
      description: description(),
      package: package(),
      source_url: "https://github.com/arjan/decorator",
      homepage_url: "https://github.com/arjan/decorator",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      docs: docs(),
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

  defp elixirrc_options(:test) do
    []
  end

  defp elixirrc_options(_) do
    [warnings_as_errors: true]
  end

  defp docs do
    [
      main: "readme",
      formatter_opts: [gfm: true],
      extras: [
        "README.md"
      ]
    ]
  end

  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end
end
