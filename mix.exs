defmodule ExLiveUrl.MixProject do
  use Mix.Project

  def project do
    [
      app: :ex_live_url,
      version: "0.2.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      name: "ExLiveUrl",
      description:
        "A collection of Phoenix LiveView lifecycle hooks and utility functions for working with URL state.",
      docs: [
        main: "ExLiveUrl"
      ],
      package: [
        licenses: ["MIT"],
        links: %{
          "GitHub" => "https://github.com/AHBruns/ex_live_url",
          "Hex" => "https://hex.pm/packages/ex_live_url"
        }
      ]
    ]
  end

  def application do
    [
      extra_applications: [:logger]
    ]
  end

  defp deps do
    [
      {:phoenix_live_view, "~> 0.18.3"},
      {:ex_doc, "~> 0.27", only: :dev, runtime: false},
      {:jason, "~> 1.4", only: :test}
    ]
  end
end
