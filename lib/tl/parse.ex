defmodule TL.Parse do
  alias TL.Schema
  import TL.Binary

  @moduledoc false

  def decode(container, content) do
    container = if is_integer(container), do: Integer.to_string(container),
      else: container
    {:match, description} = Schema.search "id", container
    expected_params = description |> Map.get("params")

    {map, tail} = extract(expected_params, content)

    name = if Map.has_key?(description, "predicate") do
      Map.get description, "predicate"
    else
      Map.get description, "method"
    end

    map = map |> Map.put(:name, name)

    {map, tail}
  end

  # Extract
  defp extract(params, data, map \\ %{})
  defp extract([], data_tail, map), do: {map, data_tail}
  defp extract([param | params_tail], data, map) do
    # Get the name and the type of the value from the structure
    name = Map.get(param, "name") |> String.to_atom
    type = Map.get(param, "type") |> String.to_atom

    # Deserialize and map
    {value, data_tail} = deserialize(data, type, :return_tail)
    map = map |> Map.put(name, value)

    # Iterate on the next element
    extract params_tail, data_tail, map
  end

  # Deserialize
  def deserialize(value, type) do
    {value, _} = deserialize(value, type, :return_tail)
    value
  end

  # Deserialize the first element of the binary (given its type). Return the
  # tail.
  defp deserialize(data, type, :return_tail) do
    case type do
    # Basic types
      :meta32 ->
        {head, tail} = binary_split(data, 4)
        <<value::signed-little-size(4)-unit(8)>> = head
        {value, tail}
      :meta64 ->
        {head, tail} = binary_split(data, 8)
        <<value::signed-little-size(8)-unit(8)>> = head
        {value, tail}
      :int ->
        {head, tail} = binary_split(data, 4)
        <<value::signed-little-size(4)-unit(8)>> = head
        {value, tail}
      :int64 ->
        {head, tail} = binary_split(data, 8)
        <<value::signed-big-size(8)-unit(8)>> = head
        {value, tail}
      :int128 ->
        {head, tail} = binary_split(data, 16)
        <<value::signed-big-size(16)-unit(8)>> = head
        {value, tail}
      :int256 ->
        {head, tail} = binary_split(data, 32)
        <<value::signed-big-size(32)-unit(8)>> = head
        {value, tail}
      :long ->
        {head, tail} = binary_split(data, 8)
        <<value::unsigned-little-size(8)-unit(8)>> = head
        {value, tail}
      :double ->
        {head, tail} = binary_split(data, 8)
        <<value::signed-little-size(2)-unit(32)>> = head
        {value, tail}
      :string ->
        {prefix_length, string_length, total_length} = string_length(data)
        string = :binary.part(data, prefix_length, string_length)
        tail = :binary.part(data, total_length, byte_size(data) - total_length)
        {string, tail}

        # Bytes are handled as strings
      :bytes ->
        deserialize(data, :string, :return_tail)

        # Anything else. Either a vector or a boxed type
      _ ->
        if Atom.to_string(type) =~ ~r/^vector/ui do
          deserialize(:vector, data, type)
        else
          deserialize(:boxed, data, type)
        end
    end
  end

  # Deserialize a boxed element.
  defp deserialize(:boxed, data, type) do
    type = Atom.to_string(type) |> String.replace("%","")
    {map, tail} = unless (type == "Object") do
      container = type # "Ojbect"
      decode(container, data)
    else
      container = :binary.part(data, 0, 4) |> deserialize(:int)
      content = :binary.part(data, 4, byte_size(data) - 4)
      decode(container, content)
    end

    {map, tail}
  end

  # Deserialize a vector
  defp deserialize(:vector, data, type) do
  # Extract internal type (:Vector<type>)
  type = Atom.to_string(type) |> String.split(~r{<|>})
         |> Enum.at(1)
         |> String.to_atom

         # check vector id, size & offset
         vector = :binary.part(data, 0, 4) |> deserialize(:meta32)
         {size, offset} =
           if (vector == 0x1cb5c415) do
             {:binary.part(data, 4, 4) |> deserialize(:meta32), 8}
           else
             {:binary.part(data, 0, 4) |> deserialize(:meta32), 4}
           end

           # {value, tail}
           deserialize(:vector, :binary.part(data, offset, byte_size(data) - offset), size, type)
  end

  defp deserialize(meta, data, size, type, values \\ [])
  defp deserialize(:vector, tail, 0, _, values), do: {values, tail}
  defp deserialize(:vector, data, size, type, values) do
    {value, tail} = deserialize(data, type, :return_tail)
    values = values ++ [value]

    # loop
    size = size - 1
    deserialize(:vector, tail, size, type, values)
  end

  # Compute the prefix, content and total (including prefix and padding) length
  # of a serialized string
  # See : https://core.telegram.org/mtproto/serialize#base-types
  defp string_length(data) do
    p = fn x ->
      y = (x - Float.floor x)
      case y do
        0.0 -> 0
        _ -> (1-y) * 4 |> round
      end
    end

    <<len::size(1)-unit(8)>> = :binary.part data,0, 1
    if len < 254 do
      div = (1 + len) / 4
      padding = p.(div)
      {1, len, 1+len+padding}
    else
      <<str_len::little-size(3)-unit(8)>> = :binary.part data ,1 ,3
      div = (4 + str_len) / 4
      padding = p.(div)
      {4, str_len, 4 + str_len + padding }
    end
  end
 end
