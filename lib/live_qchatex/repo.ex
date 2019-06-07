defmodule LiveQchatex.Repo do
  use Supervisor

  require Logger

  alias LiveQchatex.Models

  # @TODO Avoid this for create_tables!()
  @models [Models.Chat, Models.User, Models.Message]

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    # @TODO Implement config to [disc_copies: nodes] for tables
    setup_database!(%{})
    children = []

    Supervisor.init(children, strategy: :one_for_one)
  end

  def subscribe(topic) do
    # LiveQchatexWeb.Endpoint.subscribe(topic)
    Phoenix.PubSub.subscribe(LiveQchatex.PubSub, topic)
  end

  def broadcast(data, topic, event) do
    # LiveQchatexWeb.Endpoint.broadcast(topic, event, data)
    Phoenix.PubSub.broadcast_from(LiveQchatex.PubSub, self(), topic, {event, data})
  end

  def broadcast_all(data, topic, event) do
    Phoenix.PubSub.broadcast(LiveQchatex.PubSub, topic, {event, data})
  end

  def broadcast_event({:ok, result}, topic, event) do
    broadcast(result, topic, event)
    {:ok, result}
  end

  def broadcast_event(result, _topic, _event), do: result

  @spec cast(Memento.Table.record(), Map.t()) :: Memento.Table.record()
  def cast(model, attrs) do
    attrs
    |> to_atom_map()
    |> Enum.reduce(model, fn {k, v}, acc ->
      if Map.has_key?(acc, k),
        do: acc |> Map.put(k, v),
        else: acc
    end)
  end

  def to_atom_map(map) do
    map
    |> Enum.reduce(%{}, fn {k, v}, acc ->
      atom = to_string(k) |> String.to_existing_atom()
      acc |> Map.put(atom, v)
    end)
  end

  @spec write(Memento.Table.record(), Map.t()) :: {:ok, Memento.Table.record()} | {:error, any()}
  def write(model, attrs \\ %{}) do
    try do
      Memento.transaction!(fn ->
        %{} = result = model |> cast(attrs) |> Memento.Query.write()
        Logger.debug("Repo.write() OK: #{inspect(result)}")
        {:ok, result}
      end)
    rescue
      err ->
        Logger.debug("Repo.write() ERROR: #{inspect(err)}")
        {:error, err}
    end
  end

  @spec delete(Memento.Table.record()) :: {:ok, Memento.Table.record()} | {:error, any()}
  def delete(model) do
    try do
      Memento.transaction!(fn ->
        :ok = model |> Memento.Query.delete_record()
        Logger.debug("Repo.delete() OK: #{inspect(model)}")
        {:ok, model}
      end)
    rescue
      err ->
        Logger.debug("Repo.delete() ERROR: #{inspect(err)}")
        {:error, err}
    end
  end

  @spec read(Memento.Table.name(), term()) :: {:ok, Memento.Table.record()} | {:error, any()}
  def read(model, id) do
    try do
      Memento.transaction!(fn ->
        %{} = result = model |> Memento.Query.read(id)
        Logger.debug("Repo.read() OK: #{inspect(result)}")
        {:ok, result}
      end)
    rescue
      err ->
        Logger.debug("Repo.read() ERROR: #{inspect(err)}")
        {:error, err}
    end
  end

  @spec find(Memento.Table.name(), Tuple.t() | list(Tuple.t())) ::
          {:ok, list(Memento.Table.record())} | {:error, any()}
  def find(model, guards \\ {}) do
    try do
      Memento.transaction!(fn ->
        result = model |> Memento.Query.select(guards)
        Logger.debug("Repo.find() OK: #{inspect(result)}")
        {:ok, result}
      end)
    rescue
      err ->
        Logger.debug("Repo.find() ERROR: #{inspect(err)}")
        {:error, err}
    end
  end

  @spec count(Memento.Table.name()) :: Integer.t()
  def count(model) do
    Memento.Table.info(model, :size)
  end

  @spec random_string(non_neg_integer()) :: binary()
  def random_string(length) do
    :crypto.strong_rand_bytes(length) |> Base.url_encode64() |> binary_part(0, length)
  end

  # @TODO Use config to [disc_copies: nodes] for tables
  defp setup_database!(_config, nodes \\ [node()]) do
    create_schema!(nodes)
    create_tables!(nodes)
  end

  defp create_schema!(nodes) do
    Memento.stop()

    case Memento.Schema.create(nodes) do
      :ok -> :ok
      {:error, {_, {:already_exists, _}}} -> :ok
      {:error, reason} -> raise reason
    end

    :ok = Memento.start()
  end

  defp create_tables!(nodes) do
    failed =
      @models
      |> Enum.map(fn m -> {m, create_table(nodes, m)} end)
      |> Enum.reject(fn {_, status} -> status == :ok end)

    if length(failed) > 0 do
      raise "Some tables couldn't be created: #{inspect(failed)}"
    end

    :ok
  end

  defp create_table(nodes, model),
    # do: create_table(Memento.Table.create(model))
    do: create_table(Memento.Table.create(model, disc_copies: nodes))

  defp create_table({:error, {:already_exists, _}}), do: :ok
  defp create_table(:ok), do: :ok
  defp create_table(err), do: err
end
