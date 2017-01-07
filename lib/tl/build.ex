defmodule TL.Build do
  alias TL.Schema

  @moduledoc false

  def encode(container, content) do
    {:match, description} = Schema.search "method_or_predicate", container
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
                        |> serialize(:head4)

    # Build the final payload
    serialized_method <> :binary.list_to_bin serialized_values
  end

  # Serialize a value given its type
  def serialize(data, type) do
    case type do
      :int -> <<data::signed-little-size(1)-unit(32)>>
      :int128 -> <<data::signed-big-size(16)-unit(8)>>
      :int256 -> <<data::signed-big-size(32)-unit(8)>>
      :long -> <<data::unsigned-little-size(8)-unit(8)>>
      :double -> <<data::signed-little-size(2)-unit(32)>>
      :string -> serialize_string(data)
      :head4 -> <<data::little-signed-size(4)-unit(8)>>
      :head8 -> <<data::little-signed-size(8)-unit(8)>>
      :bytes ->
        bin =
          if (is_binary data), do: data, else: encode_signed(data)
        serialize_string(bin)
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

  # From int to bin
  def encode_signed(int) do
    size = (:math.log2(abs(int)) + 1) / 8.0 |> Float.ceil |> round
    <<int::signed-size(size)-unit(8)>>
  end
end
