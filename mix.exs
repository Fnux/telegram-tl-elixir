defmodule TL.Mixfile do
  use Mix.Project

  def project do
    [app: :telegram_tl,
     version: "0.1.1-beta",
     elixir: "~> 1.4",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     description: description(),
     package: package(),
     deps: deps(),

     # Docs
     name: "Telegram TL",
     source_url: "https://github.com/fnux/telegram-tl-elixir",
     homepage_url: "http://github.com/fnux/telegram-tl-elixir",
     docs: [main: "readme", extras: ["README.md"]]]
  end

  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [extra_applications: [], mod: {TL.Schema, []}]
  end

  # Depedencies. Type "mix help deps" for more examples and options
  defp deps do
    [{:poison, "~> 3.1"}, {:ex_doc, "~> 0.14", only: :dev}]
  end

  defp description do
    """
    Serialize and deserialize elements of the TL language.
    """
  end

  defp package do
    [
     name: :telegram_tl,
     files: ["lib", "priv", "mix.exs", "README*", "LICENSE*"],
     maintainers: ["Timothée Floure"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/Fnux/telegram-tl-elixir"}]
  end
end
