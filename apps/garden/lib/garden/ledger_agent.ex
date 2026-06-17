defmodule Garden.LedgerAgent do
  use GenServer

  @table :garden_ledger

  def start_link(opts \\ []) do
    GenServer.start_link(
      __MODULE__,
      opts,
      name: __MODULE__
    )
  end

  @impl true
  def init(_) do
    :ets.new(
      @table,
      [
        :named_table,
        :ordered_set,
        :public,
        read_concurrency: true
      ]
    )

    {:ok, %{sequence: 0}}
  end

  def append(event_type, payload \\ %{}) do
    GenServer.call(
      __MODULE__,
      {:append, event_type, payload}
    )
  end

  def entries do
    :ets.tab2list(@table)
    |> Enum.map(fn {_, entry} -> entry end)
  end

  def latest(limit \\ 10) do
    entries()
    |> Enum.reverse()
    |> Enum.take(limit)
  end

  @impl true
  def handle_call(
        {:append, event_type, payload},
        _from,
        state
      ) do
    id = state.sequence + 1

    entry = %{
      id: id,
      event_type: event_type,
      payload: payload,
      timestamp: DateTime.utc_now()
    }

    :ets.insert(
      @table,
      {id, entry}
    )

    {:reply,
     {:ok, entry},
     %{state | sequence: id}}
  end
end
