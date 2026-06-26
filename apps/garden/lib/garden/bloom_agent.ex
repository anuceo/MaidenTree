defmodule Garden.BloomAgent do
  use GenServer

  def start_link(opts \\ []) do
    GenServer.start_link(
      __MODULE__,
      opts,
      name: __MODULE__
    )
  end

  def init(state) do
    {:ok, state}
  end

  def bloom(parent_id, attrs \\ %{}) do
    GenServer.call(
      __MODULE__,
      {:bloom, parent_id, attrs}
    )
  end

  def handle_call(
        {:bloom, parent_id, attrs},
        _from,
        state
      ) do
    child_id =
      "node_" <>
        Integer.to_string(
          System.unique_integer([:positive])
        )

    now = DateTime.utc_now()

    node =
      %{
        id: child_id,
        parent_id: parent_id,
        epoch_id:
          Map.get(attrs, :epoch_id, "epoch_0"),
        entropy:
          Map.get(attrs, :entropy, 1.0),
        stability:
          Map.get(attrs, :stability, 1.0),
        children: [],
        created_at: now,
        updated_at: now
      }

    Garden.MemoryNode.insert(node)

    link_parent(parent_id, child_id)

    Garden.LedgerAgent.append(
      :node_bloomed,
      %{
        parent_id: parent_id,
        child_id: child_id
      }
    )

    {:reply, {:ok, node}, state}
  end

  defp link_parent(nil, _child_id) do
    :ok
  end

  defp link_parent(parent_id, child_id) do
    case Garden.MemoryNode.get(parent_id) do
      {:ok, parent} ->
        children =
          [child_id | parent.children]

        Garden.MemoryNode.update(
          parent_id,
          %{children: children}
        )

      _ ->
        :ok
    end
  end
end
