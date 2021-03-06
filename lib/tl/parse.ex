defmodule TL.Parse do
  require Bitwise
  import TL.Binary
  alias TL.Schema

  @moduledoc false

  ###############################
  # Process "structured" messages

  def decode(container, content, key \\ "id") do
    # Cast the container to a string (?)
    container = if is_integer(container) do
      Integer.to_string(container)
    else
      container
    end

    {status, result} = Schema.search key, container
    if status == :match do
      description = result |> List.first

      expected_params = description |> Map.get("params")

      name = if Map.has_key?(description, "predicate") do
        Map.get description, "predicate"
      else
        Map.get description, "method"
      end

      # Handle flags
      {expected_params, content} = parse_flags(expected_params, content)

      {map, tail} = case name do
        "vector" -> 
          {list, tail} = deserialize(content, :vector, :return_tail)
          {%{value: list}, tail}
        _ -> extract(expected_params, content)
      end

      # Add the object of the predicate to the returned map
      map = map |> Map.put(:name, name)

      # parse objects such as gzip_packed
      map = if Map.get(description, "type") == "Object" do
        process(:object, map)
      else
        map
      end

      {map, tail}
    else
      {{:error, "Unable to find container #{container} in the Schema!"}, content}
    end
  end

  defp parse_flags([], content), do: {[], content}
  defp parse_flags(expected_params, content) do
    [first_param|params_tail] = expected_params
    {name, type} = {Map.get(first_param, "name"), Map.get(first_param, "type")}

    if {name, type} == {"flags", "#"} do
      {flags, content_tail} = deserialize(content, :int, :return_tail)
      processed_params = process_flags(params_tail, flags)
      {processed_params, content_tail}
    else # don't change anything
      {expected_params, content}
    end
  end

  defp process_flags(input_params, flags, processed_params \\ [])
  defp process_flags([], _flags, processed_params), do: processed_params
  defp process_flags([param|tail], flags, processed_params) do
    name = Map.get(param, "name")
    type = Map.get(param, "type")

    returned_params = if Regex.match?(~r/^flags.\d*\?.*$/ui, type) do
      [_, index, wrapped_type] = Regex.run(
        ~r/^flags.(\d*)\?(.*)$/ui, type
      )
      index = String.to_integer(index)
      pow_index = :math.pow(2, index) |> round

      if (Bitwise.band(flags, pow_index) == pow_index) do
        processed_params ++ [%{"name" => name, "type" => wrapped_type}]
      else
        processed_params
      end
    else
      processed_params ++ [param]
    end
    process_flags(tail, flags, returned_params)
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

  #################
  # Deserialization

  # Deserialize
  def deserialize(value, type) do
    {value, _} = deserialize(value, type, :return_tail)
    value
  end

  # Deserialize the first element of the binary (given its type). Return the
  # tail.
  defp deserialize(data, type, :return_tail) do
    #IO.inspect {type, data}
    case type do
    # Basic types
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
        <<value::signed-little-size(8)-unit(8)>> = head
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
      :vector ->
        unbox(:vector, data)
      :true -> {true, data} # workaround for flags.X?true
      # Anything else.
      _ ->
        cond do
          Atom.to_string(type) =~ ~r/^vector/ui -> unbox(:vector, data, type)
          true -> unbox(:object, data, type)
        end
    end
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

  ####################################
  # Deserialization of "evolued" types

  def process(:object, map) do
    name = map |> Map.get(:name)

    case name do
      "gzip_packed" ->
        gzip = Map.get(map, :packed_data)
        data = :zlib.gunzip(gzip)

        container = :binary.part(data, 0, 4) |> deserialize(:int)
        content = :binary.part(data, 4, byte_size(data) - 4)
        {unpacked, __} = decode(container, content)
        %{map | packed_data: unpacked}
      _ -> map
    end
  end

  # Vector deserialization
  def unbox(:vector, data) do
    count = :binary.part(data, 0, 4) |> deserialize(:int)
    value = :binary.part(data, 4, byte_size(data) - 4)
    unbox(:vector, value, count, [])
  end

  # Deserialize a boxed element.
  defp unbox(:object, data, type) do
    type = Atom.to_string(type) |> String.replace("%","")

    {map, tail} = cond do # bof
      type in ["message", "future_salt"] ->
        content = :binary.part(data, 0, byte_size(data) - 0)
        decode(type, content, "method_or_predicate")
      true ->
        container = :binary.part(data, 0, 4) |> deserialize(:int)
        content = :binary.part(data, 4, byte_size(data) - 4)
        decode(container, content, "id")
    end

    {map, tail}
  end

  # Vector deserialization
  defp unbox(:vector, data, type) do
    # Extract internal type (:Vector<type>)
    type = Atom.to_string(type) |> String.split(~r{<|>})
         |> Enum.at(1)
         |> String.replace("%","")
         |> String.downcase
         |> String.to_atom

    # check vector id, size & offset
    vector = :binary.part(data, 0, 4) |> deserialize(:int)

    # WTF!?
    {count, offset} =
      if (vector == 0x1cb5c415) do
        {:binary.part(data, 4, 4) |> deserialize(:int), 8}
      else
        {:binary.part(data, 0, 4) |> deserialize(:int), 4}
      end

    value = :binary.part(data, offset, byte_size(data) - offset)

    # {value, tail}
    unbox(:vector, value, count, [], type)
  end

  defp unbox(_, _, _, _, type \\ :from_schema) # header
  defp unbox(:vector, tail, 0, output, _), do: {output, tail}
  defp unbox(:vector, data, count, output, type) do
    # The `message` predicate exists in both the TL and API schemas --'
    # This part is somewhat ugly but I suppose I still have to discover  a lot
    # of special cases... Will figure out later.
    case type do
      :message -> # Workaround for get_dialogs
        container = :binary.part(data, 0, 4) |> deserialize(:int)
        {status, _} = Schema.search "id", Integer.to_string(container)
        if status == :match do
          unbox(:vector, data, count, output, :from_schema)
        else # status == :nothing
          {map, tail} = dispatch(:vector, type, data)
          unbox(:vector, tail, count - 1, (output ++ [map]), type)
        end
      :from_schema -> # Search for the container in the schema
        container = :binary.part(data, 0, 4) |> deserialize(:int)
        content = :binary.part(data, 4, byte_size(data) - 4)
        {map, tail} = dispatch(:vector, container, content)

        unbox(:vector, tail, count - 1, (output ++ [map]))
      _ ->
        {map, tail} = dispatch(:vector, type, data)
        unbox(:vector, tail, count - 1, (output ++ [map]), type)
    end
  end

  defp dispatch(:vector, type, data) do
    # returns {map, tail}
    cond do
      is_atom(type) -> deserialize(data, type, :return_tail)
      is_binary(type) -> decode(type, data, "method_or_predicate")
      true -> decode(type, data)
    end
  end
end
