defmodule TL.Build do
  alias TL.Schema
  import TL.Binary

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

  # Serialize a value given its type
  def serialize(data, type) do
    case type do
      :int -> <<data::signed-little-size(4)-unit(8)>>
      :int64 -> <<data::signed-big-size(8)-unit(8)>>
      :int128 -> <<data::signed-big-size(16)-unit(8)>>
      :int256 -> <<data::signed-big-size(32)-unit(8)>>
      :long -> <<data::signed-little-size(8)-unit(8)>>
      :double -> <<data::signed-little-size(2)-unit(32)>>
      :string -> serialize_string(data)
      :bytes ->
        bin =
          if (is_binary data), do: data, else: encode_signed(data)
        serialize_string(bin)
      :"#" ->
        serialize(0,:int) # ¯\(ツ)/¯ (issue 3)
      _ ->
        cond do
          Atom.to_string(type) =~ ~r/^vector/ui -> box(:vector, data, type)
          Atom.to_string(type) =~ ~r/^flags.\d\?[a-zA-Z]*$/ui -> <<>> # ¯\(ツ)/¯ (issue 3)
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
