defmodule Garden.MemoryNode do
  use GenServer

  @table :memory_nodes

  def start_link(opts \\ []) do
    GenServer.start_link(
      __MODULE__,
      opts,
      name: __MODULE__
    )
  end

  def init(_) do
    :ets.new(
      @table,
      [
        :named_table,
        :set,
        :public,
        read_concurrency: true
      ]
    )

    {:ok, %{}}
  end

  def insert(node) do
    now = DateTime.utc_now()

    node =
      node
      |> Map.put_new(:parent_id, nil)
      |> Map.put_new(:epoch_id, "epoch_0")
      |> Map.put_new(:entropy, 1.0)
      |> Map.put_new(:stability, 1.0)
      |> Map.put_new(:children, [])
      |> Map.put_new(:created_at, now)
      |> Map.put_new(:updated_at, now)

    :ets.insert(
      @table,
      {node.id, node}
    )
  end

  def get(id) do
    case :ets.lookup(@table, id) do
      [{_, node}] -> {:ok, node}
      [] -> {:error, :not_found}
    end
  end

  def update(node_id, updates) do
    case get(node_id) do
      {:ok, node} ->
        updated =
          node
          |> Map.merge(updates)
          |> Map.put(:updated_at, DateTime.utc_now())

        :ets.insert(@table, {node_id, updated})

        {:ok, updated}

      error ->
        error
    end
  end

  def all do
    :ets.tab2list(@table)
    |> Enum.map(fn {_, node} -> node end)
  end
end
