# Telegram-TL

This library allows you to serialize and deserialize elements of the
[TL Language](https://core.telegram.org/mtproto/TL). Take a look to the
documentation of the `TL` module for basic usage.

*Since it dynamically match maps against TL schemas, it's far from
being efficient and is pretty slow. However, it 'just works'
the way it is so let's say it's okay for now. A 'static' version
directly generated from TL schemas may come later.*

The package and its documentation are on
[hex.pm](https://hex.pm/packages/telegram_tl). It was originally
designed to be used by
[telegram-mt-elixir](https://github.com/Fnux/telegram-mt-elixir).



## Configuration

If no configuration is specified, the API layer 57 **[1]** will be used.
Although this library was only tested with layer versions 23 and 57, you can
specify a custom source in you `config.exs` :

```
config :telegram_tl, tl_path: "/path/to/mtproto.json",
                     api_version: 57,
                     api_path: "/path/to/api-layer-57.json"

```

**[1]** : the last documented version (on [telegram.org](https://telegram.org/))
is [API layer 23](https://core.telegram.org/schema?layer=23).
