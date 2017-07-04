defmodule TL.Schema do
  use GenServer

  @moduledoc """
  Parse and search the MTProto TL-schema (See
  [core.telegram.org/schema/mtproto](https://core.telegram.org/schema/mtproto))
  and the API TL-schema (See
  [core.telegram.org/schema](https://core.telegram.org/schema)).
  """

  @tl "mtproto.json"
  @api_layer 23
  @api "api-layer-#{@api_layer}.json"
  @name MTProtoSchemaStore

  ### Schema store

  @doc false
  def start(_, _), do: TL.Schema.start_link()

  @doc false
  def start_link() do
    GenServer.start_link(__MODULE__, [], name: @name)
  end

  @doc false
  def init(_) do
    {:ok, tl_raw} = Path.join(:code.priv_dir(:telegram_tl), @tl) |> File.read
    {:ok, api_row} = Path.join(:code.priv_dir(:telegram_tl), @api) |> File.read
    tl = Poison.Parser.parse! tl_raw
    api = Poison.Parser.parse! api_row

    state = %{tl: tl, api: api}
    {:ok, state}
  end

  @doc false
  def handle_call(:tl, _from, state) do
    {:reply, state.tl, state}
  end

  @doc false
  def handle_call(:api, _from, state) do
    {:reply, state.api, state}
  end

  ### Public

  @doc """
    Return the version of the API layer used.
  """
  def api_layer_version, do: @api_layer

  @doc """
    Returns the MTProto TL-schema.
  """
  def tl do
    GenServer.call @name, :tl
  end

  @doc """
    Returns the Telegram API TL-schema.
  """
  def api do
    GenServer.call @name, :api
  end

  @doc """
  Search descriptors in the schema(s)

    * `key`
    * `container`
  """
  def search(key, container) do
    {tl_match, tl_value} = search(key, container, :tl)
    # If a match was found in the tl schema, return it. If not, search in
    # the api schema.
    if tl_match == :match do
      {:match, tl_value}
    else
      {api_match, api_value} = search(key, container, :api)
      if api_match == :match, do: {:match, api_value}, else: {:nothing, nil}
    end
  end

  @doc """
    Search the schema(s).

    * `key` - example : `"predicate"`
    * `content` - example : `"ping"`
    * `schema` - schema to search into, either `:tl` or `:api`.
  """
  def search(key, content, schema) do
    case schema do
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
