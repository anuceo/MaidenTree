defmodule Garden.WatcherAgent do
  use GenServer

  @scan_interval :timer.seconds(15)

  def start_link(opts \\ []) do
    GenServer.start_link(
      __MODULE__,
      opts,
      name: __MODULE__
    )
  end

  @impl true
  def init(state) do
    schedule_scan()

    {:ok, state}
  end

  @impl true
  def handle_info(:scan, state) do
    scan_nodes()

    schedule_scan()

    {:noreply, state}
  end

  defp schedule_scan do
    Process.send_after(
      self(),
      :scan,
      @scan_interval
    )
  end

  defp scan_nodes do
    Garden.MemoryNode.all()
    |> Enum.each(&evaluate_node/1)
  end

  defp evaluate_node(node) do
    check_entropy(node)
    check_stability(node)
    check_connectivity(node)
  end

  defp check_entropy(node) do
    entropy = Map.get(node, :entropy, 1.0)

    if entropy < 0.10 do
      emit_alert(
        :low_entropy,
        node.id,
        entropy
      )
    end
  end

  defp check_stability(node) do
    stability = Map.get(node, :stability, 1.0)

    if stability < 0.25 do
      emit_alert(
        :low_stability,
        node.id,
        stability
      )
    end
  end

  defp check_connectivity(node) do
    parent_id = Map.get(node, :parent_id)

    cond do
      parent_id == nil ->
        :ok

      Garden.MemoryNode.get(parent_id) == {:error, :not_found} ->
        emit_alert(
          :orphaned_node,
          node.id,
          parent_id
        )

      true ->
        :ok
    end
  end

  defp emit_alert(type, node_id, value) do
    Garden.LedgerAgent.append(
      :watch_alert,
      %{
        type: type,
        node_id: node_id,
        value: value
      }
    )
  end
end
