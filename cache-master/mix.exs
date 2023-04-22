defmodule Cache.MixProject do
  use Mix.Project

  def project do
    [
      app: :cache_master,
      version: "0.1.0",
      elixir: "~> 1.12.2",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :crypto],
      mod: {CacheMaster, []},
      env: [
        port_for_client: 6666,
        port_for_slave: 6667
      ]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
		{:poison, "~> 4.0"}
    ]
  end
end
