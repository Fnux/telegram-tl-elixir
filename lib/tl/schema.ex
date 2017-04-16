defmodule TL.Schema do
  @moduledoc """
  Parse and search the MTProto TL-schema (See
  [core.telegram.org/schema/mtproto](https://core.telegram.org/schema/mtproto))
  and the API TL-schema (See
  [core.telegram.org/schema](https://core.telegram.org/schema)).
  """

  @tl "mtproto.json"
  @api_layer 23
  @api "api-layer-#{@api_layer}.json"

  @doc """
    Return the version of the API layer used.
  """
  def api_layer_version, do: @api_layer

  @doc """
    Parse the MTProto TL-schema and returns a map.
  """
  def tl do
    path = Path.join(:code.priv_dir(:telegram_tl), @tl)
    {:ok, tl_schema_json} = File.read path
    Poison.Parser.parse! tl_schema_json
  end

  @doc """
    Parse the Telegram API TL-schema and returns a map.
  """
  def api do
    path = Path.join(:code.priv_dir(:telegram_tl), @api)
    {:ok, api_schema_json} = File.read path
    Poison.Parser.parse! api_schema_json
  end

  @doc """
    Search the schema(s).

    * `key` - example : `"predicate"`
    * `content` - example : `"ping"`
    * `schema` - schema to search into, either `:tl`, `:api` or `:both` (default).
  """
  def search(key, content, schema \\ :both) do
    case schema do
      :both ->
        {tl_match, tl_value} = search(key, content, :tl)
        # If a match was found in the tl schema, return it. If not, search in
        # the api schema.
          if tl_match == :match do
            {:match, tl_value}
          else
            {api_match, api_value} = search(key, content, :api)
            if api_match == :match, do: {:match, api_value}, else: {:nothing, nil}
          end
      :tl -> search_schema(key, content, tl())
      :api -> search_schema(key, content, api())
      _ -> {:err, nil}
    end
  end

  defp search_schema(key, value, schema) do
    methods = search_methods(key, value, schema)
    constructors = search_constructors(key, value, schema)
    result = methods ++ constructors
    if Enum.empty? result do
      {:nothing, []}
    else
      {:match, result}
    end
  end

  defp search_methods(key, value, schema) do
    key = if (key == "method_or_predicate"), do: "method", else: key
    schema = Map.get(schema, "methods")
  match(key, value, schema)
  end

  defp search_constructors(key, value, schema) do
    key = if (key == "method_or_predicate"), do: "predicate", else: key
    schema = Map.get(schema, "constructors")
  match(key, value, schema)
  end

  defp match(key, value, schema) do
    Enum.filter schema, fn
      x -> Map.get(x, key) == value
    end
  end
end
