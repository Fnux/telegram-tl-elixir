defmodule TL.Schema do
  @moduledoc """
  Parse and search the MTProto TL-schema (See
  [core.telegram.org/schema/mtproto](https://core.telegram.org/schema/mtproto))
  and the API TL-schema (See [core.telegram.org/schema]
  (https://core.telegram.org/schema)).
  """

  @tl "priv/mtproto.json"
  @api_layer 23
  @api "priv/api-layer-#{@api_layer}.json"

  @doc """
    Return the version of the API layer used.
  """
  def api_layer_version, do: @api_layer

  @doc """
    Return the MTProto TL-schema as a map.
  """
  def tl do
    {:ok, tl_schema_json} = File.read @tl
    {:ok, tl_schema} = JSON.decode tl_schema_json
    tl_schema
  end

  @doc """
    Return the API TL-schema as a map. Use `TL.Schema.api_layer_version/0` to
    get the layer version.
  """
  def api do
    {:ok, api_schema_json} = File.read @api
    {:ok, api_schema} = JSON.decode api_schema_json
    api_schema
  end

  @doc """
    Search the schema(s).
  """
  def search(key, content, schema \\ :both) do
    case schema do
      :both ->
        {tl_match, tl_value} = search(key, content, :tl)
        # If a match was found in the tl schema, return it. If not, search in
        # the api schema.
        {status, value} =
          if tl_match == :match do
            {:ok, tl_value}
          else
            {api_match, api_value} = search(key, content, :api)
            if api_match == :match, do: {:ok, api_match}, else: {:err, nil}
          end
      :tl -> schema_search(key, content, Schema.tl)
      :api -> schema_search(key, content, Schema.api)
      _ -> {:error}
    end
  end

  defp schema_search(key, content, schema) do
    description = Enum.filter schema, fn
      x -> Map.get(x, key) == content
    end

    if Enum.is_empty? description do
      {:nothing, nil}
    else
      {:match, Enum.first(description)}
    end
  end
 end
