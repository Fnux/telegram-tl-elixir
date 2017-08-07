defmodule TL.Build do
  require Bitwise
  import TL.Binary
  alias TL.Schema

  @moduledoc false

  def encode(container, content) do
    {:match, result} = Schema.search "method_or_predicate", container
    description = result |> List.first
    expected_params = description |> Map.get("params")

    # Map values to their types
    map = Enum.map expected_params,fn x ->
      {
        Map.get(x, "type") |> String.to_atom,
        Map.get(content, String.to_atom Map.get(x, "name"))
      }
    end

    # Handle flags
    map = process_flags(map)

    # Serialized values
    serialized_values = map |> Enum.map(fn {type, value} -> serialize(value, type) end)

    # Seralize the constructor
    serialized_method = description
                        |> Map.get("id")
                        |> String.to_integer
                        |> serialize(:int)

    # Build the final payload
    serialized_method <> :binary.list_to_bin serialized_values
  end

  # Handle flags
  def process_flags(input_params, flags \\ 0, processed_params \\ [])
  def process_flags([], _flags, processed_params), do: processed_params
  def process_flags([param|params_tail], flags, processed_params) do
    {type, value} = param
    cond do
      {type, value} == {:"#", nil} ->
        flags_value = 0
        process_flags(params_tail, flags_value, processed_params ++ [int: flags_value])
      type == :"#" && is_list(value) ->
        flags_value = TL.Binary.build_integer_from_bits_list(value)
        process_flags(params_tail, flags_value, processed_params ++ [int: flags_value])
      Regex.match?(~r/^flags.\d*\?.*$/ui , Atom.to_string(type)) ->
        [_, index, wrapped_type] = Regex.run(
          ~r/^flags.(\d*)\?(.*)$/ui, Atom.to_string(type)
        )

        index = String.to_integer(index)
        pow_index = :math.pow(2, index) |> round

        if (Bitwise.band(flags, pow_index) == pow_index) do
          returned_params = processed_params ++ [{String.to_atom(wrapped_type), value}]
          process_flags(params_tail, flags, returned_params)
        else
          process_flags(params_tail, flags, processed_params)
        end

      true -> process_flags(params_tail, flags, processed_params ++ [param])
    end
  end

  # Serialize a value given its type
  def serialize(data, type) do
    #IO.inspect {type, data}
    case type do
      :int -> <<data::signed-little-size(4)-unit(8)>>
      :int64 -> <<data::signed-big-size(8)-unit(8)>>
      :int128 -> <<data::signed-big-size(16)-unit(8)>>
      :int256 -> <<data::signed-big-size(32)-unit(8)>>
      :long -> <<data::signed-little-size(8)-unit(8)>>
      :double -> <<data::signed-little-size(2)-unit(32)>>
      :string -> serialize_string(data)
      :true -> <<>> # flags
      :bytes ->
        bin =
          if (is_binary data), do: data, else: encode_signed(data)
        serialize_string(bin)
      _ ->
        cond do
          Atom.to_string(type) =~ ~r/^vector/ui -> box(:vector, data, type)
          true -> data
        end
    end
  end

  defp serialize_string(string) do
    len = byte_size string

    p = fn x ->
      y = (x - Float.floor x)
      case y do
        0.0 -> 0
        _ -> (1-y) * 4 |> round
      end
    end

    if len <= 253 do
      div = (len + 1) / 4
      padding = p.(div)
      <<len>> <> string <> <<0::size(padding)-unit(8)>>
    else
      div = (len + 4) / 4
      padding = p.(div)
      <<254>> <> <<len::little-size(3)-unit(8)>> <> string <> <<0::size(padding)-unit(8)>>
    end
  end

  defp box(:vector, data, type) do
    # Extract internal type (:Vector<type>)
    type = Atom.to_string(type) |> String.split(~r{<|>})
         |> Enum.at(1)
         |> String.replace("%","")
         |> String.downcase
         |> String.to_atom

    # get vector predicate
    {:match, result} = Schema.search("predicate", "vector")
    vector = result |> List.first
                    |> Map.get("id")
                    |> String.to_integer
                    |> serialize(:int)

    size = Enum.count(data) |> serialize(:int)
    serialized_data = (for e <- data, do: serialize(e, type)) |> Enum.join

    # Return serialized vector
    vector <> size <> serialized_data
  end
 end
