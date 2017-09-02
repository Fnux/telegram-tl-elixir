defmodule TL.Binary do
  @moduledoc """
  A few methods extending erlang's `:binary` module.
  """

  @doc """
  Converts a (signed) integer to its binary representation.

  ## Examples

  ```
  iex> TL.Binary.encode_signed 666
  <<2, 154>>
  iex> TL.Binary.encode_signed -666
  <<253, 102>>
  ```
  """
  def encode_signed(int) do
    size = (:math.log2(abs(int))) / 8.0 |> Float.ceil |> round
    <<int::signed-size(size)-unit(8)>>
  end

  @doc """
  Converts the binary representation (of a signed integer) to its decimal
  representation.

  ## Examples

  ```
  iex> TL.Binary.decode_signed <<2, 154>>
  666
  iex> TL.Binary.decode_signed <<253, 102>>
  -666
  ```
  """
  def decode_signed(binary) do
    binary_length = byte_size binary
    <<int::signed-size(binary_length)-unit(8)>> = binary
    int
  end

  @doc """
  Split a binary at the given index.

  ## Example

  ```
  iex> TL.Binary.binary_split <<1, 2, 3, 4, 5, 6, 7, 8, 9, 10>>, 3
  {<<1, 2, 3>>, <<4, 5, 6, 7, 8, 9, 10>>}
  ```
  """
  def binary_split(binary, index) do
    left = :binary.part binary, 0, index
    right = :binary.part binary, index, byte_size(binary) - index
    {left, right}
  end

  def build_integer_from_bits_list(list, value \\ 0)
  @doc false
  def build_integer_from_bits_list([], value), do: value
  @doc """
  Build an integer from a list of bit positions.

  ## Example

  ```
  iex> TL.Binary.build_integer_from_bits_list([0,1,3,10])
  1035 # = 2^0 + 2^1 + 2^3 + 2^10
  ```
  """
  def build_integer_from_bits_list([bit_index|tail], value) do
    bit_value = :math.pow(2, bit_index) |> round()
    build_integer_from_bits_list(tail, value + bit_value)
  end

  @doc """
  Reverse the endianness of a binary.

  ## Example

  ```
  iex> TL.Binary.reverse_endianness(<<1,2,3>>)
  <<3,2,1>>
  ```
  """
  def reverse_endianness(bytes) do
    bytes |> :binary.bin_to_list
          |> Enum.reverse
          |> :binary.list_to_bin
  end
end
