defmodule Garden.CycleAgent do
  use GenServer

  @cycle_interval :timer.seconds(30)

  def start_link(opts \\ []) do
    GenServer.start_link(
      __MODULE__,
      opts,
      name: __MODULE__
    )
  end

  @impl true
  def init(state) do
    schedule_cycle()

    {:ok,
     Map.merge(
       %{
         cycle_count: 0,
         last_cycle_at: nil
       },
       Map.new(state)
     )}
  end

  @impl true
  def handle_info(:cycle, state) do
    run_cycle(state)

    next_state = %{
      state
      | cycle_count: state.cycle_count + 1,
        last_cycle_at: DateTime.utc_now()
    }

    schedule_cycle()

    {:noreply, next_state}
  end

  def stats do
    GenServer.call(__MODULE__, :stats)
  end

  @impl true
  def handle_call(:stats, _from, state) do
    {:reply, state, state}
  end

  defp schedule_cycle do
    Process.send_after(
      self(),
      :cycle,
      @cycle_interval
    )
  end

  defp run_cycle(state) do
    IO.puts("""
    [CYCLE]
    Cycle ##{state.cycle_count + 1}
    Started: #{DateTime.utc_now()}
    """)

    bloom_phase()
    watch_phase()
    prune_phase()

    emit_cycle_metrics(state)

    IO.puts("[CYCLE] completed")
  end

  defp bloom_phase do
    :ok
  end

  defp watch_phase do
    pid = Process.whereis(Garden.WatcherAgent)

    if pid do
      send(pid, :scan)
    end
  end

  defp prune_phase do
    :ok
  end

  defp emit_cycle_metrics(state) do
    Garden.LedgerAgent.append(
      :cycle_complete,
      %{
        cycle: state.cycle_count + 1,
        timestamp: DateTime.utc_now()
      }
    )
  end
end
