defmodule LiveQchatex.Repo do
  use Supervisor

  require Logger

  alias LiveQchatex.Models

  @models [Models.Chat, Models.User, Models.Message]

  def start_link(init_arg) do
    Supervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @impl true
  def init(_init_arg) do
    init_mnesia!()
    Supervisor.init([], strategy: :one_for_one)
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

  @spec to_atom_map(Map.t()) :: Map.t()
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
        Logger.debug("Repo.write(#{inspect(model.__struct__)}) OK: #{inspect(result)}")
        {:ok, result}
      end)
    rescue
      err ->
        Logger.debug("Repo.write(#{inspect(model.__struct__)}) ERROR: #{inspect(err)}")
        {:error, err}
    end
  end

  @spec update(Memento.Table.record(), Map.t()) :: {:ok, Memento.Table.record()} | {:error, any()}
  def update(model = %{__struct__: table}, attrs) do
    try do
      Memento.transaction!(fn ->
        data = Memento.Query.read(table, model.id, lock: :write)
        %{} = result = data |> cast(attrs) |> Memento.Query.write()
        Logger.debug("Repo.update(#{inspect(table)}) OK: #{inspect(result)}")
        {:ok, result}
      end)
    rescue
      err ->
        Logger.debug("Repo.update(#{inspect(table)}) ERROR: #{inspect(err)}")
        {:error, err}
    end
  end

  @spec read(Memento.Table.name(), term()) :: {:ok, Memento.Table.record()} | {:error, any()}
  def read(model, id) do
    try do
      Memento.transaction!(fn ->
        %{} = result = model |> Memento.Query.read(id)
        Logger.debug("Repo.read(#{inspect(model)}) OK: #{inspect(result)}")
        {:ok, result}
      end)
    rescue
      err ->
        Logger.debug("Repo.read(#{inspect(model)}) ERROR: #{inspect(err)}")
        {:error, err}
    end
  end

  @spec delete(Memento.Table.record()) :: {:ok, Memento.Table.record()} | {:error, any()}
  def delete(model) do
    try do
      Memento.transaction!(fn ->
        :ok = model |> Memento.Query.delete_record()
        Logger.debug("Repo.delete(#{inspect(model.__struct__)}) OK: #{inspect(model)}")
        {:ok, model}
      end)
    rescue
      err ->
        Logger.debug("Repo.delete(#{inspect(model.__struct__)}) ERROR: #{inspect(err)}")
        {:error, err}
    end
  end

  @spec delete_all(Memento.Table.name(), Tuple.t() | list(Tuple.t())) ::
          {:ok, list(Memento.Table.record())} | {:error, any()}
  def delete_all(model, guards \\ []) do
    try do
      Memento.transaction!(fn ->
        results =
          model
          |> Memento.Query.select(guards)
          |> Enum.filter(&(:ok == Memento.Query.delete_record(&1)))

        Logger.debug("Repo.delete_all(#{inspect(model)}) OK: #{inspect(results)}")
        {:ok, results}
      end)
    rescue
      err ->
        Logger.debug("Repo.delete_all(#{inspect(model)}) ERROR: #{inspect(err)}")
        {:error, err}
    end
  end

  @spec find(Memento.Table.name(), Tuple.t() | list(Tuple.t())) ::
          {:ok, list(Memento.Table.record())} | {:error, any()}
  def find(model, guards \\ []) do
    try do
      Memento.transaction!(fn ->
        result = model |> Memento.Query.select(guards)
        Logger.debug("Repo.find(#{inspect(model)}) OK: #{inspect(result)}")
        {:ok, result}
      end)
    rescue
      err ->
        Logger.debug("Repo.find(#{inspect(model)}) ERROR: #{inspect(err)}")
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

  ############################## MNESIA CLUSTERED INIT ##############################

  defp init_mnesia!() do
    wait_for_nodes_connections()

    case find_active_cluster_nodes(Node.list()) do
      [] -> init_cluster!([node()])
      nodes -> join_cluster!(nodes)
    end
  end

  defp wait_for_nodes_connections(),
    do: [Logger.info("Waiting for nodes connections.."), wait_for_nodes_connections(1)]

  defp wait_for_nodes_connections(count) when count <= 10 do
    if Node.list() == [],
      do: [Process.sleep(500), wait_for_nodes_connections(count + 1)],
      else: Logger.info("Nodes connections detected: #{inspect(Node.list())}")
  end

  defp wait_for_nodes_connections(_),
    do: Logger.info("No nodes connections detected!")

  defp find_active_cluster_nodes(nodes),
    do: Enum.filter(nodes, &(:rpc.block_call(&1, :mnesia, :system_info, [:is_running]) == :yes))

  defp init_cluster!(nodes) do
    desc = "at #{inspect(nodes)}"

    with :ok <- start_mnesia(nodes),
         :ok <- change_table_copy_type(),
         :ok <- create_tables(nodes),
         :ok <- wait_for_tables() do
      Logger.info("Mnesia started with cluster initialized #{desc}", ansi_color: :yellow)
    else
      {_, reason} ->
        raise "Couldn't initialize mnesia cluster #{desc}: #{inspect(reason)}"
    end
  end

  defp join_cluster!(nodes) do
    desc = "for #{inspect(node())} at #{inspect(nodes)}"

    with :ok <- start_mnesia(nodes),
         :ok <- connect_to_cluster(nodes),
         :ok <- change_table_copy_type(),
         :ok <- sync_tables(),
         :ok <- wait_for_tables() do
      Logger.info("Mnesia started and joined cluster nodes #{desc}", ansi_color: :yellow)
    else
      {_, reason} ->
        raise "Couldn't join mnesia cluster #{desc}: #{inspect(reason)}"
    end
  end

  defp start_mnesia(nodes) do
    case init_schema(nodes) do
      :ok ->
        case Memento.start() do
          :ok -> :ok
          {:error, {:already_started, :mnesia}} -> :ok
          err -> err
        end

      err ->
        err
    end
  end

  defp init_schema(nodes) do
    Logger.info("Mnesia is stopping for schema initialization..")
    Memento.stop()

    @models
    |> Enum.map(&:mnesia.set_master_nodes(&1, nodes))

    if nodes != [node()] do
      # Ensure to remove the local schema if this node will be an slave!
      # This is due to the fact that this node could have an schema
      # already created with another mnesia cookie, because it was created
      # in a point of time where no other nodes were available
      Memento.Schema.delete([node()])
    end

    case Memento.Schema.create(nodes) do
      :ok -> :ok
      {:error, {_, {:already_exists, _}}} -> :ok
      {:error, reason} -> {:error, "Couldn't create mnesia schema: #{inspect(reason)}"}
    end
  end

  defp create_tables(nodes) do
    @models
    |> Enum.map(&create_table(nodes, &1))
    |> Enum.reject(&(&1 == :ok))
    |> case do
      [] -> :ok
      failed -> {:error, "Some tables couldn't be created: #{inspect(failed)}"}
    end
  end

  defp create_table(nodes, model),
    do: model |> Memento.Table.create(disc_copies: nodes) |> create_table()

  defp create_table(:ok), do: :ok
  defp create_table({:error, {:already_exists, _}}), do: :ok
  defp create_table(err), do: err

  defp connect_to_cluster(nodes) do
    case :mnesia.change_config(:extra_db_nodes, nodes) do
      {:ok, _} -> :ok
      err -> err
    end
  end

  defp change_table_copy_type() do
    case :mnesia.change_table_copy_type(:schema, node(), :disc_copies) do
      {:atomic, :ok} -> :ok
      {:aborted, {:already_exists, :schema, _, _}} -> :ok
      err -> err
    end
  end

  defp sync_tables() do
    @models
    |> Enum.map(fn model ->
      case :mnesia.add_table_copy(model, node(), :disc_copies) do
        {:atomic, :ok} -> :ok
        {:aborted, {:already_exists, _, _}} -> :ok
        err -> err
      end
    end)
    |> Enum.reject(&(&1 == :ok))
    |> case do
      [] -> :ok
      failed -> {:error, "Some tables couldn't be synced: #{inspect(failed)}"}
    end
  end

  defp wait_for_tables() do
    case :mnesia.wait_for_tables(@models, :timer.seconds(10)) do
      :ok -> :ok
      {:timeout, tables} -> {:error, "Timeout for tables #{inspect(tables)}"}
      err -> err
    end
  end
end
