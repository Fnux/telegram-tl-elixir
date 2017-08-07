defmodule TL.Binary do
  @moduledoc """
    Helpers to work with binaries.
  """

  @doc """
    Converts a (signed) integer to its binary representation.
  """
  def encode_signed(int) do
    size = (:math.log2(abs(int))) / 8.0 |> Float.ceil |> round
    <<int::signed-size(size)-unit(8)>>
  end

  @doc """
    Converts the binary representation (of a signed integer) to its decimal
    representation.
  """
  def decode_signed(binary) do
    binary_length = byte_size binary
    <<int::signed-size(binary_length)-unit(8)>> = binary
    int
  end

  @doc """
    Split a binary at the given index.
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

  Example:
  ```
  iex> build_integer_from_bits_list([0,1,3,10])
  1035
  ```
  """
  def build_integer_from_bits_list([bit_index|tail], value) do
    bit_value = :math.pow(2, bit_index) |> round()
    build_integer_from_bits_list(tail, value + bit_value)
  end
end
