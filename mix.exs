defmodule TL.Mixfile do
  use Mix.Project

  def project do
    [app: :tl,
     version: "0.0.1-alpha",
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
     docs: [main: "TL"]]
  end

  # Type "mix help compile.app" for more information
  def application do
  # Specify extra applications you'll use from Erlang/Elixir
  [extra_applications: [:logger]]
  end

  # Depedencies. Type "mix help deps" for more examples and options
  defp deps do
    [{:json, "~> 1.0.0"}, {:ex_doc, "~> 0.14.5", ony: :dev}]
  end

  defp description do
    """
    This library allows you to serialize and deserialize elements of the
    [TL Language](https://core.telegram.org/mtproto/TL). It was originally
    designed to be used by
    [telegram-mt-elixir](https://github.com/Fnux/telegram-mt-elixir).
    """
  end

  defp package do
    [
     name: :telegram_tl,
     files: ["lib", "priv", "mix.exs", "README*", "readme*", "LICENSE*", "license*"],
     maintainers: ["Timothée Floure"],
     licenses: ["MIT"],
     links: %{"GitHub" => "https://github.com/Fnux/telegram-tl-elixir"}]
  end
end
