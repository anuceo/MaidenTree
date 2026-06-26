defmodule Garden.SeedVault do
  use GenServer

  @table :garden_seed_vault

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
        :set,
        :public,
        read_concurrency: true
      ]
    )

    {:ok, %{}}
  end

  def store_seed(seed_id, seed_data, metadata \\ %{}) do
    GenServer.call(
      __MODULE__,
      {:store_seed, seed_id, seed_data, metadata}
    )
  end

  def get_seed(seed_id) do
    case :ets.lookup(@table, seed_id) do
      [{_, seed}] ->
        {:ok, seed}

      [] ->
        {:error, :not_found}
    end
  end

  def list_seeds do
    :ets.tab2list(@table)
    |> Enum.map(fn {_, seed} -> seed end)
  end

  def validate_mount(seed_id) do
    case get_seed(seed_id) do
      {:ok, seed} ->
        {:ok,
         %{
           seed_id: seed.id,
           mountable: true
         }}

      error ->
        error
    end
  end

  def verify_access(seed_id, glyph_id) do
    with {:ok, seed} <- get_seed(seed_id),
         true <- seed.metadata.glyph_id == glyph_id do
      :ok
    else
      _ ->
        {:error, :unauthorized}
    end
  end

  @impl true
  def handle_call(
        {:store_seed, seed_id, seed_data, metadata},
        _from,
        state
      ) do
    seed = %{
      id: seed_id,
      data: seed_data,
      metadata: metadata,
      created_at: DateTime.utc_now()
    }

    :ets.insert(
      @table,
      {seed_id, seed}
    )

    Garden.LedgerAgent.append(
      :seed_stored,
      %{
        seed_id: seed_id
      }
    )

    {:reply, {:ok, seed}, state}
  end
end
