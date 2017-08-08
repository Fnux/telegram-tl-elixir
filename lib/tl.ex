defmodule TL do
  @moduledoc """
  Telegram TL : base module.
  """

  @doc """
  Build a TL object. See
  [core.telegram.org/schema/mtproto](https://core.telegram.org/schema/mtproto)
  and [core.telegram.org/schema](https://core.telegram.org/schema).

  **About flags :** you must provide the index of the enabled flags in the `flags`
  field. Except for `flags.X?true`, any enabled flag must be provided with a value.

  ## Example

      iex> TL.build "ping", %{:ping_id => 666}
      <<236, 119, 190, 122, 154, 2, 0, 0, 0, 0, 0, 0>>

      # Flags, example for :
      # auth.sendCode#86aef0ec flags:# allow_flashcall:flags.0?true phone_number:string current_number:flags.0?Bool api_id:int api_hash:string = auth.SentCode;
      # Here flags with index '0' ([0]) are enabled. If you want to enable
      # flags with index 0, 2 or 4 : [0,2,4].
      iex> TL.build("auth.sendCode", %{flags: [0], phone_number: "0041763332222", sms_type: 0, api_id: 1234, api_hash: "hashashash", lang_code: "en", current_number: "BoolFalse"})
      <<236, 240, 174, 134, 1, 0, 0, 0, 13, 48, 48, 52, 49, 55, 54, 51, 51, 51, 50,
      50, 50, 50, 0, 0, 66, 111, 111, 108, 70, 97, 108, 115, 101, 210, 4, 0, 0, 10,
      104, 97, 115, 104, 97, 115, 104, 97, 115, 104, 0>>
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
