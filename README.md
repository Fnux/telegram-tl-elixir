# Telegram-TL

This library allows you to serialize and deserialize elements of the
[TL Language](https://core.telegram.org/mtproto/TL). It was originally
designed to be used by
[telegram-mt-elixir](https://github.com/Fnux/telegram-mt-elixir).

The package and its documentation are on
[hex.pm](https://hex.pm/packages/telegram_tl).

## Configuration

If no configuration is specified, the API layer 57 **[1]** will be used.
Although this library was only tested with the above layer version, you can
specify a custom source in you `config.exs` :

```
config :telegram_tl, tl_path: "/path/to/mtproto.json",
                     api_version: 57,
                     api_path: "/path/to/api-layer-57.json"

```

**[1]** : the last documented version is [API layer 23](https://core.telegram.org/schema?layer=23).
