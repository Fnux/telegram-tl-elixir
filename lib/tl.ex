defmodule TL do
  @moduledoc """
  Documentation for TL. @TODO
  """

  @doc """
    Build a TL object.
  """
  def build(container, content), do: TL.Build.encode(container, content)

  @doc """
    Decode a TL object.
  """
  def parse(container, content), do: TL.Parse.decode(container, content)

  @doc """
    Serialize an object given its type.
  """
  def serialize(data, type), do: TL.Build.serialize(data, type)

  @doc """
    Deserialize an object given its type.
  """
  def deserialize(data, type), do: TL.Parse.deserialize(data, type)
end
