defmodule TL.Schema do
  use GenServer

  @moduledoc """
  Parse and search the MTProto TL-schema (See
  [core.telegram.org/schema/mtproto](https://core.telegram.org/schema/mtproto))
  and the API TL-schema (See
  [core.telegram.org/schema](https://core.telegram.org/schema) for API layer 23).
  """

  @default_api_layer 57
  @default_api_path Path.join(:code.priv_dir(:telegram_tl), "api-layer-57.json")
  @default_tl_path Path.join(:code.priv_dir(:telegram_tl), "mtproto.json")
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
    {:ok, tl_raw} = get_tl_path() |> File.read
    {:ok, api_row} = get_api_path() |> File.read
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

  @doc false
  def get_api_path do
    config = Application.get_env(:telegram_tl, :api_path)
    if config, do: config, else: @default_api_path
  end

  @doc false
  def get_tl_path do
    config = Application.get_env(:telegram_tl, :tl_path)
    if config, do: config, else: @default_tl_path
  end

  ### Public

  @doc """
  Return the version of the API layer used.

  ## Example

  ```
  iex> TL.Schema.api_layer_version
  57
  ```
  """
  def api_layer_version do
    config = Application.get_env(:telegram_tl, :api_layer)
    if config, do: config, else: @default_api_layer
  end

  @doc """
  Returns the MTProto TL-schema.

  ## Example

  ```
  iex> TL.Schema.tl
  %{"constructors" => [%{"id" => "481674261", "params" => [],
    "predicate" => "vector", "type" => "Vector t"},
                       %{"id" => "85337187", "params" => ... %},
                       ...]}
    ```
  """
  def tl do
    GenServer.call @name, :tl
  end

  @doc """
  Returns the Telegram API TL-schema.

  ## Example

  ```
  iex> TL.Schema.api
  %{"constructors" => [%{"id" => "-1132882121", "params" => [],
    "predicate" => "boolFalse", "type" => "Bool"}, ...], ...}
  """
  def api do
    GenServer.call @name, :api
  end

  @doc """
  Search descriptors in the schema(s)

    * `key` : field name
    * `value` : field value

  ## Examples

  ```
  iex> TL.Schema.search "method", "messages.setTyping"
  {:match,
  [%{"id" => "-1551737264", "method" => "messages.setTyping",
    "params" => [%{"name" => "peer", "type" => "InputPeer"},
     %{"name" => "action", "type" => "SendMessageAction"}], "type" => "Bool"}]}
  iex> TL.Schema.search "id", "-1551737264"
  {:match,
  [%{"id" => "-1551737264", "method" => "messages.setTyping",
    "params" => [%{"name" => "peer", "type" => "InputPeer"},
     %{"name" => "action", "type" => "SendMessageAction"}], "type" => "Bool"}]}
  iex> TL.Schema.search "method", "unknown_method"
  {:nothing, nil}
  iex> TL.Schema.search "method_or_predicate", "messages.sendMedia" # to search in both method and predicates
  {:match, ...}
  ```
  """
  def search(key, value) do
    {tl_match, tl_value} = search(key, value, :tl)
    # If a match was found in the tl schema, return it. If not, search in
    # the api schema.
    if tl_match == :match do
      {:match, tl_value}
    else
      {api_match, api_value} = search(key, value, :api)
      if api_match == :match, do: {:match, api_value}, else: {:nothing, nil}
    end
  end

  @doc """
  Search in a specific schema.

  * `key` - example : `"predicate"`
  * `value` - example : `"ping"`
  * `schema` - schema to search into, either `:tl` or `:api`.
  """
  def search(key, value, schema) do
    case schema do
      :tl -> search_schema(key, value, tl())
      :api -> search_schema(key, value, api())
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
