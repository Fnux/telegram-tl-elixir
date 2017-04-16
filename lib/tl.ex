defmodule TL do
  @moduledoc """
  This library allows you to serialize and deserialize elements of the
  [TL Language](https://core.telegram.org/mtproto/TL). It was originally
  designed to be used with
  [telegram-mt-elixir](https://github.com/Fnux/telegram-mt-elixir).
  """

  @doc """
  Build a TL object. See
  [core.telegram.org/schema/mtproto](https://core.telegram.org/schema/mtproto)
  and [core.telegram.org/schema](https://core.telegram.org/schema).

  ## Example

      iex> TL.build "ping", %{:ping_id => 666}
      <<236, 119, 190, 122, 154, 2, 0, 0, 0, 0, 0, 0>>
  """
  def build(container, content), do: TL.Build.encode(container, content)

  @doc """
  Decode a TL object.  See
  [core.telegram.org/schema/mtproto](https://core.telegram.org/schema/mtproto)
  and [core.telegram.org/schema](https://core.telegram.org/schema).

  ## Examples

      iex> TL.parse 0x7abe77ec, <<154, 2, 0, 0, 0, 0, 0, 0>>
      {%{name: "ping", ping_id: 666}, ""}

      iex> TL.parse 0x7abe77ec, <<154, 2, 0, 0, 0, 0, 0, 0, 1, 2, 3, 4>>
      {%{name: "ping", ping_id: 666}, <<1, 2, 3, 4>>}
  """
  def parse(container, content), do: TL.Parse.decode(container, content)

  @doc """
  Serialize an object given its type. Available types :

    * `:int`
    * `:int64`
    * `:int128`
    * `:int256`
    * `:long`
    * `:float`
    * `:string`
    * `:bytes`
    * `:vector`

  ## Examples

      iex> TL.serialize(123456789, :int128)
      <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 91, 205, 21>>

      iex> TL.serialize("Hello world!", :string)
      <<12, 72, 101, 108, 108, 111, 32, 119, 111, 114, 108, 100, 33, 0, 0, 0>>
  """
  def serialize(data, type), do: TL.Build.serialize(data, type)

  @doc """
    Deserialize an object given its type. Available types :

    * `:int`
    * `:int64`
    * `:int128`
    * `:int256`
    * `:long`
    * `:float`
    * `:string`
    * `:bytes`
    * `:vector`
    * `:boxed`

  ## Example

      iex(12)> TL.deserialize(<<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 7, 91, 205, 21>>, :int128)
      123456789
  """
  def deserialize(data, type), do: TL.Parse.deserialize(data, type)
end
