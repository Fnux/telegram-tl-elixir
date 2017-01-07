defmodule TL.Binary do
  @moduledoc """
    @TODO
  """

  @doc """
    Converts a (signed) integer to the smallest possible representation in a
    binary digit representation.
  """
  def encode_signed(int) do
    size = (:math.log2(abs(int)) + 1) / 8.0 |> Float.ceil |> round
    <<int::signed-size(size)-unit(8)>>
  end

  @doc """
    Converts the binary digit representation (of a signed integer) to a signed
    integer.
  """
  def decode_signed(binary) do
    binary_length = byte_size binary
    <<int::signed-size(binary_length)-unit(8)>> = binary
    int
  end

  @doc """
    Split a binary in two at the given index.
  """
  def binary_split(binary, index) do
    left = :binary.part binary, 0, index
    right = :binary.part binary, index, byte_size(binary) - index
    {left, right}
  end
end
