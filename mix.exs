defmodule Decorator.Mixfile do
  use Mix.Project

  @source_url "https://github.com/arjan/decorator"
  @version File.read!("VERSION")

  def project do
    [
      app: :decorator,
      version: @version,
      elixir: "~> 1.11",
      elixirc_options: elixirrc_options(Mix.env()),
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs(),
      package: package()
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp elixirrc_options(:test), do: []
  defp elixirrc_options(_), do: [warnings_as_errors: true]

  defp deps do
    [
      {:ex_doc, ">= 0.0.0", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      extras: ["README.md"],
      main: "readme",
      formatter_opts: [gfm: true],
      homepage_url: @source_url,
      source_url: @source_url,
      api_reference: false
    ]
  end

  defp package do
    [
      description: description(),
      files: ["lib", "mix.exs", "*.md", "LICENSE", "VERSION"],
      maintainers: ["Arjan Scherpenisse"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url}
    ]
  end

  defp description do
    "Function decorators for Elixir"
  end
end
